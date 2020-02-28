import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/tax_rate/tax_rate_actions.dart';
import 'package:invoiceninja_flutter/ui/app/entities/entity_actions_dialog.dart';
import 'package:invoiceninja_flutter/ui/app/lists/list_divider.dart';
import 'package:invoiceninja_flutter/ui/app/loading_indicator.dart';
import 'package:invoiceninja_flutter/ui/app/help_text.dart';
import 'package:invoiceninja_flutter/ui/tax_rate/tax_rate_list_item.dart';
import 'package:invoiceninja_flutter/ui/tax_rate/tax_rate_list_vm.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';

class TaxRateList extends StatelessWidget {
  const TaxRateList({
    Key key,
    @required this.viewModel,
  }) : super(key: key);

  final TaxRateListVM viewModel;

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of<AppState>(context);
    final listUIState = store.state.uiState.taxRateUIState.listUIState;
    final isInMultiselect = listUIState.isInMultiselect();

    return Column(
      children: <Widget>[
        Expanded(
          child: !viewModel.isLoaded
              ? LoadingIndicator()
              : RefreshIndicator(
                  onRefresh: () => viewModel.onRefreshed(context),
                  child: viewModel.taxRateList.isEmpty
                      ? HelpText(AppLocalization.of(context).noRecordsFound)
                      : ListView.separated(
                          shrinkWrap: true,
                          separatorBuilder: (context, index) => ListDivider(),
                          itemCount: viewModel.taxRateList.length,
                          itemBuilder: (BuildContext context, index) {
                            final taxRateId = viewModel.taxRateList[index];
                            final taxRate = viewModel.taxRateMap[taxRateId];

                            void showDialog() => showEntityActionsDialog(
                                  entities: [taxRate],
                                  context: context,
                                );

                            return TaxRateListItem(
                              user: viewModel.userCompany.user,
                              filter: viewModel.filter,
                              taxRate: taxRate,
                              onTap: () =>
                                  viewModel.onTaxRateTap(context, taxRate),
                              onEntityAction: (EntityAction action) {
                                if (action == EntityAction.more) {
                                  showDialog();
                                } else {
                                  handleTaxRateAction(
                                      context, [taxRate], action);
                                }
                              },
                              onLongPress: () async {
                                final longPressIsSelection = store
                                        .state
                                        .prefState
                                        .longPressSelectionIsDefault ??
                                    true;
                                if (longPressIsSelection && !isInMultiselect) {
                                  handleTaxRateAction(context, [taxRate],
                                      EntityAction.toggleMultiselect);
                                } else {
                                  showDialog();
                                }
                              },
                              isChecked: isInMultiselect &&
                                  listUIState.isSelected(taxRate.id),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}