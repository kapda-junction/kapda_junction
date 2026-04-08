import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/remote/product_datasource.dart';
import '../../../data/datasources/remote/upload_datasource.dart';
import '../../../domain/entities/product.dart';

part 'products_event.dart';
part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductDataSource _ds;

  ProductsBloc(this._ds, UploadDataSource _) : super(ProductsInitial()) {
    on<ProductsLoadRequested>(_onLoad);
    on<ProductDeleteRequested>(_onDelete);
    on<ProductSaveRequested>(_onSave);
  }

  Future<void> _onLoad(ProductsLoadRequested e, Emitter<ProductsState> emit) async {
    emit(ProductsLoading());
    try {
      final r = await _ds.getProducts(page: e.page, search: e.search, category: e.category);
      emit(ProductsLoaded(products: r.products, total: r.total, pages: r.pages, page: e.page));
    } catch (err) {
      emit(ProductsFailure(err.toString()));
    }
  }

  Future<void> _onDelete(ProductDeleteRequested e, Emitter<ProductsState> emit) async {
    try {
      await _ds.deleteProduct(e.id);
      if (state is ProductsLoaded) {
        final s = state as ProductsLoaded;
        emit(s.copyWith(products: s.products.where((p) => p.id != e.id).toList()));
      }
    } catch (err) {
      emit(ProductsFailure(err.toString()));
    }
  }

  Future<void> _onSave(ProductSaveRequested e, Emitter<ProductsState> emit) async {
    emit(ProductsSaving());
    try {
      if (e.id != null) {
        await _ds.updateProduct(e.id!, e.data);
      } else {
        await _ds.createProduct(e.data);
      }
      emit(ProductSaveSuccess());
    } catch (err) {
      emit(ProductsFailure(err.toString()));
    }
  }
}
