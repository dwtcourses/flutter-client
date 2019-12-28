import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:invoiceninja_flutter/data/web_client.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:invoiceninja_flutter/ui/app/debug/state_inspector.dart';
import 'package:invoiceninja_flutter/ui/app/dialogs/alert_dialog.dart';
import 'package:invoiceninja_flutter/ui/app/dialogs/error_dialog.dart';
import 'package:invoiceninja_flutter/ui/app/loading_indicator.dart';
import 'package:invoiceninja_flutter/ui/app/resources/cached_image.dart';
import 'package:invoiceninja_flutter/utils/dialogs.dart';
import 'package:invoiceninja_flutter/utils/pdf.dart';
import 'package:redux/redux.dart';
import 'package:invoiceninja_flutter/.env.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/dashboard/dashboard_actions.dart';
import 'package:invoiceninja_flutter/redux/settings/settings_actions.dart';
import 'package:invoiceninja_flutter/ui/app/menu_drawer_vm.dart';
import 'package:invoiceninja_flutter/ui/app/lists/selected_indicator.dart';
import 'package:invoiceninja_flutter/utils/icons.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:invoiceninja_flutter/utils/platforms.dart';
import 'package:url_launcher/url_launcher.dart';

// STARTER: import - do not remove comment

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({
    Key key,
    @required this.viewModel,
  }) : super(key: key);

  final MenuDrawerVM viewModel;

  @override
  Widget build(BuildContext context) {
    final Store<AppState> store = StoreProvider.of<AppState>(context);
    final state = store.state;
    final enableDarkMode = state.prefState.enableDarkMode;
    final localization = AppLocalization.of(context);
    final company = viewModel.selectedCompany;

    if (company == null) {
      return Container();
    }

    Widget _companyLogo(CompanyEntity company) =>
        company.settings.companyLogo != null &&
                company.settings.companyLogo.isNotEmpty
            ? CachedImage(
                width: double.infinity,
                height: 30,
                url: company.settings.companyLogo,
              )
            : Image.asset('assets/images/logo.png', width: 37, height: 37);

    Widget _companyListItem(CompanyEntity company) => Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            _companyLogo(company),
            SizedBox(width: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    company.displayName,
                    style: Theme.of(context).textTheme.subhead,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(viewModel.user.email,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.caption)
                ],
              ),
            ),
          ],
        );

    final _collapsedCompanySelector = PopupMenuButton<String>(
      tooltip: localization.selectCompany,
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: _companyLogo(viewModel.selectedCompany),
      ),
      itemBuilder: (BuildContext context) => viewModel.companies
          .map((company) => PopupMenuItem<String>(
                child: _companyListItem(company),
                value: company.id,
              ))
          .toList(),
      onSelected: (String companyId) {
        print('>> Selected: $companyId');
      },
    );

    final _expandedCompanySelector = DropdownButtonHideUnderline(
        child: DropdownButton<String>(
      isExpanded: true,
      icon: Icon(Icons.arrow_drop_down),
      value: viewModel.selectedCompanyIndex,
      items: viewModel.companies
          .map((CompanyEntity company) => DropdownMenuItem<String>(
                value: (viewModel.companies.indexOf(company)).toString(),
                child: _companyListItem(company),
              ))
          .toList(),
      onChanged: (value) {
        viewModel.onCompanyChanged(
            context, value, viewModel.companies[int.parse(value)]);
      },
    ));

    return SizedBox(
      width: state.prefState.isMenuCollapsed ? 65 : kDrawerWidth,
      child: Drawer(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              // Hide options while refreshing data
              state.credentials.token.isEmpty
                  ? Expanded(
                      child: LoadingIndicator(
                        height: 30,
                      ),
                    )
                  : Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                      color: enableDarkMode ? Colors.white10 : Colors.grey[200],
                      child: state.prefState.isMenuCollapsed
                          ? _collapsedCompanySelector
                          : _expandedCompanySelector),
              state.credentials.token.isEmpty
                  ? SizedBox()
                  : Expanded(
                      child: ListView(
                      shrinkWrap: true,
                      children: <Widget>[
                        DrawerTile(
                          company: company,
                          icon: kIsWeb
                              ? Icons.dashboard
                              : FontAwesomeIcons.tachometerAlt,
                          title: localization.dashboard,
                          onTap: () => store.dispatch(
                              ViewDashboard(navigator: Navigator.of(context))),
                          onLongPress: () => store.dispatch(ViewDashboard(
                              navigator: Navigator.of(context), filter: '')),
                        ),
                        DrawerTile(
                          company: company,
                          entityType: EntityType.client,
                          icon: getEntityIcon(EntityType.client),
                          title: localization.clients,
                        ),
                        DrawerTile(
                          company: company,
                          entityType: EntityType.product,
                          icon: getEntityIcon(EntityType.product),
                          title: localization.products,
                        ),
                        DrawerTile(
                          company: company,
                          entityType: EntityType.invoice,
                          icon: getEntityIcon(EntityType.invoice),
                          title: localization.invoices,
                        ),
                        DrawerTile(
                          company: company,
                          entityType: EntityType.payment,
                          icon: getEntityIcon(EntityType.payment),
                          title: localization.payments,
                        ),
                        DrawerTile(
                          company: company,
                          entityType: EntityType.quote,
                          icon: getEntityIcon(EntityType.quote),
                          title: localization.quotes,
                        ),
                        if (Config.DEMO_MODE) ...[
                          DrawerTile(
                            company: company,
                            entityType: EntityType.project,
                            icon: getEntityIcon(EntityType.project),
                            title: localization.projects,
                          ),
                          DrawerTile(
                            company: company,
                            entityType: EntityType.task,
                            icon: getEntityIcon(EntityType.task),
                            title: localization.tasks,
                          ),
                          DrawerTile(
                            company: company,
                            entityType: EntityType.vendor,
                            icon: getEntityIcon(EntityType.vendor),
                            title: localization.vendors,
                          ),
                          DrawerTile(
                            company: company,
                            entityType: EntityType.expense,
                            icon: getEntityIcon(EntityType.expense),
                            title: localization.expenses,
                          ),
                        ],
                        // STARTER: menu - do not remove comment
                        DrawerTile(
                          company: company,
                          icon: kIsWeb ? Icons.settings : FontAwesomeIcons.cog,
                          title: localization.settings,
                          onTap: () {
                            store.dispatch(ViewSettings(
                                navigator: Navigator.of(context),
                                company: state.company));
                          },
                        ),
                      ],
                    )),
              Align(
                child: state.prefState.isMenuCollapsed
                    ? SidebarFooterCollapsed()
                    : SidebarFooter(),
                alignment: Alignment(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawerTile extends StatelessWidget {
  const DrawerTile({
    @required this.company,
    @required this.icon,
    @required this.title,
    this.onTap,
    this.entityType,
    this.onLongPress,
    this.onCreateTap,
  });

  final CompanyEntity company;
  final EntityType entityType;
  final IconData icon;
  final String title;
  final Function onTap;
  final Function onLongPress;
  final Function onCreateTap;

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of<AppState>(context);
    final state = store.state;
    final uiState = state.uiState;
    final userCompany = state.userCompany;
    final NavigatorState navigator = Navigator.of(context);

    if (entityType != null && !userCompany.canViewOrCreate(entityType)) {
      return Container();
    } else if (!company.isModuleEnabled(entityType)) {
      return Container();
    }

    final localization = AppLocalization.of(context);
    final route = title == localization.dashboard
        ? kDashboard
        : title == localization.settings ? kSettings : entityType.name;

    Widget trailingWidget;
    if (!state.prefState.isMenuCollapsed) {
      if (title == localization.dashboard) {
        trailingWidget = IconButton(
          icon: Icon(Icons.search),
          onPressed: () {
            if (isMobile(context)) {
              navigator.pop();
            }
            store.dispatch(
                ViewDashboard(navigator: Navigator.of(context), filter: ''));
          },
        );
      } else if (userCompany.canCreate(entityType)) {
        trailingWidget = IconButton(
          icon: Icon(Icons.add_circle_outline),
          onPressed: () {
            if (isMobile(context)) {
              navigator.pop();
            }
            createEntityByType(context: context, entityType: entityType);
          },
        );
      }
    }

    return SelectedIndicator(
      isSelected: uiState.currentRoute.startsWith('/$route'),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 22),
        title: state.prefState.isMenuCollapsed ? null : Text(title),
        onTap: () => entityType != null
            ? viewEntitiesByType(context: context, entityType: entityType)
            : onTap(),
        onLongPress: () => onLongPress != null
            ? onLongPress()
            : entityType != null
                ? createEntityByType(context: context, entityType: entityType)
                : null,
        trailing: trailingWidget,
      ),
    );
  }
}

class _LinkTextSpan extends TextSpan {
  _LinkTextSpan({TextStyle style, String url, String text})
      : super(
            style: style,
            text: text ?? url,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launch(url, forceSafariVC: false);
              });
}

class SidebarFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = StoreProvider.of<AppState>(context).state;

    return Container(
      color: Theme.of(context).bottomAppBarColor,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          if (state.prefState.isMenuCollapsed) ...[
            Expanded(child: SizedBox())
          ] else ...[
            IconButton(
              icon: Icon(Icons.mail),
              onPressed: () => _showContactUs(context),
            ),
            IconButton(
              icon: Icon(Icons.help_outline),
              onPressed: () => launch('https://docs.invoiceninja.com'),
            ),
            IconButton(
              icon: Icon(Icons.forum),
              onPressed: () =>
                  launch('https://www.invoiceninja.com/forums/forum/support'),
            ),
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () => _showAbout(context),
            ),
            if (kDebugMode)
              IconButton(
                icon: Icon(Icons.memory),
                onPressed: () => showDialog<StateInspector>(
                    context: context,
                    builder: (BuildContext context) {
                      return StateInspector();
                    }),
              ),
            IconButton(
              icon: Icon(Icons.filter),
              onPressed: () => viewPdf(InvoiceEntity(), context),
            ),
            if (state.lastError.isNotEmpty && !kReleaseMode)
              IconButton(
                icon: Icon(
                  Icons.warning,
                  color: Colors.red,
                ),
                onPressed: () => showDialog<ErrorDialog>(
                    context: context,
                    builder: (BuildContext context) {
                      return ErrorDialog(
                        state.lastError,
                        clearErrorOnDismiss: true,
                      );
                    }),
              ),
            /*
          if (!Platform.isIOS &&
              isHosted(context) &&
              !isPaidAccount(context)) ...[
            Spacer(),
            FlatButton(
              child: Text(localization.upgrade),
              color: Colors.green,
              onPressed: () => showDialog<UpgradeDialog>(
                  context: context,
                  builder: (BuildContext context) {
                    return UpgradeDialog();
                  }),
            ),
            SizedBox(width: 14)
          ],
           */
          ],
        ],
      ),
    );
  }
}

class SidebarFooterCollapsed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.info_outline),
      onSelected: (value) {
        if (value == localization.about) {
          _showAbout(context);
        } else if (value == localization.contactUs) {
          _showContactUs(context);
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          child: ListTile(
            leading: Icon(Icons.mail),
            title: Text(localization.contactUs),
          ),
          value: localization.contactUs,
        ),
        PopupMenuItem<String>(
          child: ListTile(
            leading: Icon(Icons.help_outline),
            title: Text(localization.documentation),
          ),
          value: localization.documentation,
        ),
        PopupMenuItem<String>(
          child: ListTile(
            leading: Icon(Icons.forum),
            title: Text(localization.supportForum),
          ),
          value: localization.supportForum,
        ),
        PopupMenuItem<String>(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(localization.about),
          ),
          value: localization.about,
        ),
      ],
    );
  }
}

void _showContactUs(BuildContext context) {
  showDialog<ContactUsDialog>(
    context: context,
    builder: (BuildContext context) => ContactUsDialog(),
  );
}

void _showAbout(BuildContext context) {
  final localization = AppLocalization.of(context);
  final ThemeData themeData = Theme.of(context);
  final TextStyle aboutTextStyle = themeData.textTheme.body2;
  final TextStyle linkStyle =
      themeData.textTheme.body2.copyWith(color: themeData.accentColor);

  showAboutDialog(
    context: context,
    applicationName: 'Invoice Ninja',
    applicationIcon: Image.asset(
      'assets/images/logo.png',
      width: 40.0,
      height: 40.0,
    ),
    applicationVersion: 'Version: $kAppVersion',
    applicationLegalese: '© ${DateTime.now().year} Invoice Ninja',
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 24.0),
        child: RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                style: aboutTextStyle,
                text: localization.thankYouForUsingOurApp +
                    '\n\n' +
                    localization.ifYouLikeIt,
              ),
              _LinkTextSpan(
                style: linkStyle,
                url: getAppURL(context),
                text: ' ' + localization.clickHere + ' ',
              ),
              TextSpan(
                style: aboutTextStyle,
                text: localization.toRateIt,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class ContactUsDialog extends StatefulWidget {
  @override
  _ContactUsDialogState createState() => _ContactUsDialogState();
}

class _ContactUsDialogState extends State<ContactUsDialog> {
  String _message = '';
  bool _includeLogs = false;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final state = StoreProvider.of<AppState>(context).state;
    final user = state.user;

    return AlertDialog(
      contentPadding: EdgeInsets.all(25),
      title: Text(localization.contactUs),
      actions: <Widget>[
        FlatButton(
          child: Text(localization.cancel.toUpperCase()),
          onPressed: () => Navigator.pop(context),
        ),
        FlatButton(
          child: Text(localization.send.toUpperCase()),
          onPressed: () {
            Navigator.pop(context);
            if (_message.isNotEmpty) {
              WebClient()
                  .post(state.credentials.url + '/support/messages/send',
                      state.credentials.token,
                      data: json.encode({
                        'message': _message,
                        'include_logs': _includeLogs ? 'true' : 'false',
                      }))
                  .then((dynamic response) {
                showDialog<MessageDialog>(
                    context: context,
                    builder: (BuildContext context) {
                      return MessageDialog(
                          localization.yourMessageHasBeenReceived);
                    });
              }).catchError((dynamic error) {
                showErrorDialog(context: context, message: '$error');
              });
            }
          },
        ),
      ],
      content: SingleChildScrollView(
        child: Container(
          width: isMobile(context) ? null : 500,
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            TextFormField(
              enabled: false,
              decoration: InputDecoration(
                labelText: localization.from,
              ),
              initialValue: '${user.fullName} <${user.email}>',
            ),
            SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(
                labelText: localization.message,
              ),
              minLines: 4,
              maxLines: 4,
              onChanged: (value) => _message = value,
            ),
            SizedBox(height: 10),
            SwitchListTile(
              value: _includeLogs,
              onChanged: (value) {
                setState(() => _includeLogs = value);
              },
              title: Text(localization.includeRecentErrors),
              activeColor: Theme.of(context).accentColor,
            ),
          ]),
        ),
      ),
    );
  }
}
