import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:invoiceninja/data/models/models.dart';
import 'package:invoiceninja/ui/product/product_list.dart';
import 'package:invoiceninja/redux/app/app_state.dart';
import 'package:invoiceninja/redux/product/product_state.dart';
import 'package:invoiceninja/redux/product/product_actions.dart';
import 'package:invoiceninja/ui/product/product_details_vm.dart';


class ProductListVM extends StatelessWidget {
  ProductListVM({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ViewModel>(
      converter: _ViewModel.fromStore,
      builder: (context, vm) {
        return ProductList(
          productState: vm.productState,
          onProductTap: vm.onProductTap,
        );
      },
    );
  }
}

class _ViewModel {
  final ProductState productState;
  final bool loading;
  final Function(BuildContext, ProductEntity) onProductTap;

  _ViewModel({
    @required this.productState,
    @required this.loading,
    @required this.onProductTap,
  });

  static _ViewModel fromStore(Store<AppState> store) {
    return _ViewModel(
      productState: store.state.productState(),
      /*
      products: filteredProductsSelector(
        productsSelector(store.state),
        //activeFilterSelector(store.state),
      ),
      */
      loading: store.state.isLoading,
      onProductTap: (context, product) {
        store.dispatch(SelectProductAction(product));
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailsVM(id: product.id)));
      },
    );
  }
}
