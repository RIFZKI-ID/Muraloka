import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muraloka/all_code/model/art_data.dart';
import 'package:muraloka/all_code/state/home_cubit/home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  // Inisiasi dengan HomeInitial
  HomeCubit() : super(HomeInitial());

  /// Fungsi untuk mengambil data beranda
  /// Ini akan berpindah dari HomeLoading ke HomeLoaded atau HomeFailure
  void fetchData() {
    // 1. Emit Loading state
    emit(HomeLoading());

    // Simulasi loading data asinkronus (menggunakan Future.delayed)
    Future.delayed(const Duration(seconds: 1), () {
      try {
        // 2. Ambil Dummy Data dari ArtModel
        // Menggunakan dummyArts dan dummyAuthors yang ada di art_model.dart
        final resume = dummyArts.sublist(0, 3); // Ambil 3 untuk Resume
        final popular = dummyArts.reversed.toList(); // Semua untuk Popular Art
        final authors = dummyAuthors; // Semua untuk Popular Author

        // 3. Emit Loaded state dengan data yang sudah disiapkan
        emit(
          HomeLoaded(
            resumeArts: resume,
            popularArts: popular,
            popularAuthors: authors,
          ),
        );
      } catch (e) {
        // 4. Emit Failure state jika terjadi error
        // ignore: avoid_print
        print('Error fetching home data: $e');
        emit(
          const HomeFailure('Gagal memuat data beranda. Silakan coba lagi.'),
        );
      }
    });
  }
}
