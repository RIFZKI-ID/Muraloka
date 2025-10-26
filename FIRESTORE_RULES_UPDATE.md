# Firestore Rules Update - Payment Support

## Overview
Firestore security rules telah diupdate untuk mendukung payment flow dan marketplace transactions di aplikasi Muraloka.

## Tanggal Update
**25 Oktober 2025**

## Changes Made

### 1. **Store Listings Rules - Enhanced**

#### Before:
```javascript
match /artifacts/{appId}/public/data/store_listings/{listingId} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated();
  allow update, delete: if isAuthenticated() && 
    resource.data.sellerId == request.auth.uid;
}
```

#### After:
```javascript
match /artifacts/{appId}/public/data/store_listings/{listingId} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated();
  allow update: if isAuthenticated() && 
    (resource.data.sellerId == request.auth.uid || 
     request.resource.data.keys().hasAny(['purchaseCount', 'lastPurchasedAt', 'lastPurchasedBy']));
  allow delete: if isAuthenticated() && 
    resource.data.sellerId == request.auth.uid;
}
```

**Penjelasan:**
- Memisahkan `update` dan `delete` rules
- Allow `update` untuk:
  - Seller (owner listing)
  - Sistem untuk update purchase statistics (`purchaseCount`, `lastPurchasedAt`, `lastPurchasedBy`)
- Only seller yang bisa `delete` listing

### 2. **Transactions Collection - New**

```javascript
match /artifacts/{appId}/public/data/transactions/{transactionId} {
  allow read: if isAuthenticated() && 
    (resource.data.buyerId == request.auth.uid || 
     resource.data.sellerId == request.auth.uid);
  allow create: if isAuthenticated();
  allow update: if isAuthenticated() && 
    (resource.data.buyerId == request.auth.uid || 
     resource.data.sellerId == request.auth.uid);
}
```

**Penjelasan:**
- Collection untuk menyimpan payment records
- Read: Hanya buyer atau seller yang bisa lihat transaksi mereka
- Create: Semua authenticated users (untuk create transaksi baru)
- Update: Hanya buyer atau seller (untuk update status pembayaran)

**Data Structure:**
```dart
{
  'transactionId': 'tx_xxx',
  'buyerId': 'user_id',
  'sellerId': 'seller_id',
  'listingId': 'listing_id',
  'amount': 100000,
  'qrisString': '00020101...',
  'status': 'pending', // pending, completed, failed
  'createdAt': Timestamp,
  'updatedAt': Timestamp,
  'completedAt': Timestamp?, // null jika belum complete
}
```

### 3. **Purchases Collection - New**

```javascript
match /artifacts/{appId}/public/data/purchases/{purchaseId} {
  allow read: if isAuthenticated() && 
    (resource.data.buyerId == request.auth.uid || 
     resource.data.sellerId == request.auth.uid);
  allow create: if isAuthenticated();
  allow update: if isAuthenticated();
}
```

**Penjelasan:**
- Collection untuk tracking purchases/project ownership transfers
- Read: Hanya buyer atau seller
- Create: Semua authenticated users
- Update: Semua authenticated users (untuk sistem update status transfer)

**Data Structure:**
```dart
{
  'purchaseId': 'purchase_xxx',
  'buyerId': 'user_id',
  'sellerId': 'seller_id',
  'listingId': 'listing_id',
  'projectId': 'project_id',
  'transactionId': 'tx_xxx',
  'transferStatus': 'pending', // pending, completed, failed
  'purchasedAt': Timestamp,
  'transferredAt': Timestamp?,
}
```

### 4. **Private Projects Rules - Enhanced**

#### Before:
```javascript
match /projects/{projectId} {
  allow read: if isAuthenticated() && isOwner(userId);
  allow create: if isAuthenticated() && isOwner(userId);
  allow update: if isAuthenticated() && isOwner(userId);
  allow delete: if isAuthenticated() && isOwner(userId);
}
```

#### After:
```javascript
match /projects/{projectId} {
  allow read: if isAuthenticated() && isOwner(userId);
  allow create: if isAuthenticated() && isOwner(userId);
  // Allow update if owner OR if transferring ownership after purchase
  allow update: if isAuthenticated() && 
    (isOwner(userId) || 
     (request.resource.data.keys().hasAny(['purchasedFrom', 'purchasedAt']) && 
      request.auth.uid == request.resource.data.get('ownerId', '')));
  allow delete: if isAuthenticated() && isOwner(userId);
}
```

**Penjelasan:**
- Enhanced `update` rule untuk mendukung ownership transfer
- Allow update jika:
  - User adalah owner asli, ATAU
  - User sedang menerima ownership transfer (ada field `purchasedFrom` dan `purchasedAt`)
  - User ID cocok dengan new `ownerId` di request

## Payment Flow Implementation

### Phase 1: User Initiates Purchase (CURRENT)

```dart
// 1. User clicks "Buy Now" in marketplace
// 2. App fetches seller info from Firestore
final sellerDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(listing.ownerId)
    .get();

// 3. Navigate to QRIS Payment Page
final result = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => QRISPaymentPage(
      listing: listing,
      sellerName: sellerName,
    ),
  ),
);

// 4. User scans QR and confirms payment
if (result == true) {
  _showSuccess('Pembayaran berhasil!');
  await _refreshData();
}
```

### Phase 2: Backend Integration (TODO)

```dart
// After user confirms payment in QRIS page:

// 1. Create transaction record
await FirebaseFirestore.instance
    .collection('artifacts')
    .doc('muraloka_v1')
    .collection('public')
    .doc('data')
    .collection('transactions')
    .doc(transactionId)
    .set({
      'transactionId': transactionId,
      'buyerId': currentUserId,
      'sellerId': listing.ownerId,
      'listingId': listing.id,
      'amount': listing.price,
      'qrisString': qrisString,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

// 2. Verify payment with payment gateway
// (Integration with bank API or QRIS gateway)
final paymentStatus = await verifyQRISPayment(qrisString);

if (paymentStatus == 'success') {
  // 3. Transfer project ownership
  await transferProjectOwnership(
    buyerId: currentUserId,
    sellerId: listing.ownerId,
    projectId: listing.projectId,
    listingId: listing.id,
    transactionId: transactionId,
  );
  
  // 4. Update transaction status
  await updateTransactionStatus(transactionId, 'completed');
  
  // 5. Update listing stats
  await updateListingStats(listing.id);
  
  // 6. Send notifications
  await sendPurchaseNotifications(
    buyerId: currentUserId,
    sellerId: listing.ownerId,
    projectName: listing.title,
  );
}
```

### Phase 3: Project Ownership Transfer Function

```dart
Future<void> transferProjectOwnership({
  required String buyerId,
  required String sellerId,
  required String projectId,
  required String listingId,
  required String transactionId,
}) async {
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();
  
  // 1. Create purchase record
  final purchaseRef = firestore
      .collection('artifacts')
      .doc('muraloka_v1')
      .collection('public')
      .doc('data')
      .collection('purchases')
      .doc();
  
  batch.set(purchaseRef, {
    'purchaseId': purchaseRef.id,
    'buyerId': buyerId,
    'sellerId': sellerId,
    'listingId': listingId,
    'projectId': projectId,
    'transactionId': transactionId,
    'transferStatus': 'pending',
    'purchasedAt': FieldValue.serverTimestamp(),
  });
  
  // 2. Copy project to buyer's collection
  final sellerProjectRef = firestore
      .collection('artifacts')
      .doc('muraloka_v1')
      .collection('users')
      .doc(sellerId)
      .collection('projects')
      .doc(projectId);
  
  final projectSnapshot = await sellerProjectRef.get();
  final projectData = projectSnapshot.data()!;
  
  final buyerProjectRef = firestore
      .collection('artifacts')
      .doc('muraloka_v1')
      .collection('users')
      .doc(buyerId)
      .collection('projects')
      .doc(projectId);
  
  batch.set(buyerProjectRef, {
    ...projectData,
    'ownerId': buyerId,
    'purchasedFrom': sellerId,
    'purchasedAt': FieldValue.serverTimestamp(),
    'originalListingId': listingId,
  });
  
  // 3. Copy all layers
  final layersSnapshot = await sellerProjectRef
      .collection('layers')
      .get();
  
  for (var layer in layersSnapshot.docs) {
    batch.set(
      buyerProjectRef.collection('layers').doc(layer.id),
      layer.data(),
    );
  }
  
  // 4. Update purchase status
  batch.update(purchaseRef, {
    'transferStatus': 'completed',
    'transferredAt': FieldValue.serverTimestamp(),
  });
  
  // 5. Commit batch
  await batch.commit();
}
```

## Testing Checklist

### Pre-Deployment Tests ✅
- [x] Firestore rules compiled successfully
- [x] Rules deployed to Firebase
- [x] Users collection readable by authenticated users
- [x] Store listings collection permissions verified

### Payment Flow Tests (TODO)
- [ ] User can view marketplace listings
- [ ] User can access seller information
- [ ] QRIS payment page opens successfully
- [ ] QR code displays correctly
- [ ] Payment confirmation works
- [ ] Transaction record created in Firestore
- [ ] Payment gateway integration (when implemented)
- [ ] Project ownership transfer (when implemented)
- [ ] Notifications sent (when implemented)

### Security Tests (TODO)
- [ ] Users cannot read other users' transactions
- [ ] Users cannot modify transactions they don't own
- [ ] Only sellers can delete their listings
- [ ] Purchase statistics update works
- [ ] Ownership transfer requires valid purchase record

## Database Paths Reference

```
Firestore Structure:

/users/{userId}                           // User profiles (READ: all authenticated)
  - displayName, email, etc.

/artifacts/muraloka_v1/users/{userId}/projects/{projectId}
  - Private user projects
  - READ/WRITE: Owner only
  - UPDATE: Owner OR new owner during transfer
  
/artifacts/muraloka_v1/users/{userId}/projects/{projectId}/layers/{layerId}
  - Project layers
  - READ/WRITE: Project owner only

/artifacts/muraloka_v1/public/data/store_listings/{listingId}
  - Marketplace listings
  - READ: All authenticated users
  - CREATE: All authenticated users
  - UPDATE: Seller OR system (for stats)
  - DELETE: Seller only

/artifacts/muraloka_v1/public/data/transactions/{transactionId}
  - Payment transactions
  - READ: Buyer or Seller only
  - CREATE: All authenticated users
  - UPDATE: Buyer or Seller only

/artifacts/muraloka_v1/public/data/purchases/{purchaseId}
  - Purchase records & ownership transfers
  - READ: Buyer or Seller only
  - CREATE: All authenticated users
  - UPDATE: All authenticated users (for system)
```

## Security Considerations

1. **Transaction Privacy**: Only buyer dan seller yang bisa melihat transaksi mereka
2. **Purchase Verification**: Backend harus verify payment sebelum transfer ownership
3. **Idempotency**: Transaction IDs harus unique untuk prevent double-spending
4. **Audit Trail**: Semua transaksi logged dengan timestamps lengkap
5. **Data Integrity**: Gunakan Firestore batch writes untuk atomic operations

## Next Steps

1. ✅ Deploy updated Firestore rules
2. ⏳ Implement payment gateway integration
3. ⏳ Implement project ownership transfer logic
4. ⏳ Add transaction logging
5. ⏳ Implement push notifications
6. ⏳ Add purchase history page
7. ⏳ Add seller dashboard for sales tracking
8. ⏳ Implement refund mechanism
9. ⏳ Add transaction dispute handling

## Rollback Instructions

Jika ada masalah, gunakan rules sebelumnya:

```bash
# Backup current rules
cp firestore.rules firestore.rules.backup

# Deploy old rules (jika ada backup)
firebase deploy --only firestore:rules
```

Atau restore dari Firebase Console:
1. Go to Firebase Console
2. Firestore Database → Rules tab
3. Click "History"
4. Select previous version
5. Click "Restore"

## Related Files

- `firestore.rules` - Main security rules file
- `lib/all_code/page/marketplace_page.dart` - Marketplace with Buy Now
- `lib/presentation/pages/qris_payment_page.dart` - QRIS payment UI
- `lib/utils/qris_payment_service.dart` - QRIS generation service
- `lib/all_code/data_api/store_listing_repository.dart` - Firestore operations

## Support

Jika ada pertanyaan atau issues:
1. Check Firebase Console → Firestore → Rules tab untuk syntax errors
2. Check Firebase Console → Usage untuk rule evaluation stats
3. Test dengan Firebase Emulator untuk development
4. Review audit logs di Firebase Console

---

**Status**: ✅ Deployed Successfully
**Last Update**: October 25, 2025
**Version**: 2.0
