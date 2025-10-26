import 'package:equatable/equatable.dart';

/// Model untuk Item Seni/Artis
class ArtItem extends Equatable {
  final String id;
  final String imageUrl;
  final String title;
  final String subtitle;
  final bool isLiked;

  const ArtItem({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.isLiked = false,
  });

  @override
  List<Object> get props => [id, imageUrl, title, subtitle, isLiked];
}

/// Dummy Data untuk Item Seni
const List<ArtItem> dummyArts = [
  ArtItem(
    id: '1',
    imageUrl: 'https://placehold.co/600x800/8f3521/ffffff?text=Resum+1',
    title: 'Fred Sans',
    subtitle: 'Love hatin',
    isLiked: true,
  ),
  ArtItem(
    id: '2',
    imageUrl: 'https://placehold.co/600x800/35515c/ffffff?text=Pop+Art+2',
    title: 'Amelia Rose',
    subtitle: 'Galactic Dust',
    isLiked: false,
  ),
  ArtItem(
    id: '3',
    imageUrl: 'https://placehold.co/600x800/b1b1b1/ffffff?text=Abstract+3',
    title: 'Jackson Pollock',
    subtitle: 'Number 5, 1948',
    isLiked: false,
  ),
  ArtItem(
    id: '4',
    imageUrl: 'https://placehold.co/600x800/578FCA/ffffff?text=Blue+Ocean+4',
    title: 'Claude Monet',
    subtitle: 'Impression, soleil levant',
    isLiked: true,
  ),
];

/// Dummy Data untuk Artis Populer (menggunakan ArtItem juga)
const List<ArtItem> dummyAuthors = [
  ArtItem(
    id: 'a1',
    imageUrl: 'https://placehold.co/600x800/3674B5/ffffff?text=Author+1',
    title: 'Andy Warhol',
    subtitle: 'Pop Art King',
    isLiked: false,
  ),
  ArtItem(
    id: 'a2',
    imageUrl: 'https://placehold.co/600x800/A1E3F9/000000?text=Author+2',
    title: 'Vincent van Gogh',
    subtitle: 'Starry Night',
    isLiked: false,
  ),
  ArtItem(
    id: 'a3',
    imageUrl: 'https://placehold.co/600x800/D1F8EF/000000?text=Author+3',
    title: 'Leonardo da Vinci',
    subtitle: 'Mona Lisa',
    isLiked: true,
  ),
];
