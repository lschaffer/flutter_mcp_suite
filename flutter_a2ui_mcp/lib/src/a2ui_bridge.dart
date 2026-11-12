import 'package:flutter/widgets.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// JSON Map alias.
typedef JsonMap = Map<String, dynamic>;

/// Supported return types for client functions.
enum ClientFunctionReturnType {
  string,
  number,
  boolean,
  object,
  array,
  any,
  voidType,
}

/// Abstract execution context for function evaluation.
abstract class ExecutionContext {
  const ExecutionContext();
}

/// Data path for catalog data models.
class DataPath {
  final String path;
  const DataPath(this.path);
}

/// Abstract data model for catalog execution.
abstract class DataModel {
  const DataModel();
}

/// In-memory data model implementation.
class InMemoryDataModel extends DataModel {
  final Map<String, dynamic> data;
  InMemoryDataModel([Map<String, dynamic>? initial]) : data = initial ?? {};
}

/// Concrete data context wrapping a model and path.
class DataContext extends ExecutionContext {
  final DataModel model;
  final DataPath path;
  const DataContext(this.model, this.path);
}

/// Abstract client function definition.
abstract class ClientFunction {
  const ClientFunction();
  String get name;
  String get description;
  ClientFunctionReturnType get returnType;
  Schema get argumentSchema;
}

/// Synchronous client function definition.
abstract class SynchronousClientFunction extends ClientFunction {
  const SynchronousClientFunction();
  Object? executeSync(JsonMap args, ExecutionContext context);
}

/// User action event emitted from catalog item widgets.
class UserActionEvent {
  final String name;
  final String? sourceComponentId;
  final Map<String, dynamic> context;

  const UserActionEvent({
    required this.name,
    this.sourceComponentId,
    this.context = const {},
  });
}

/// Context provided to a catalog item widget builder.
class CatalogItemContext {
  final String id;
  final dynamic data;
  final BuildContext buildContext;
  final void Function(UserActionEvent event)? onDispatchEvent;
  final ExecutionContext? dataContext;

  CatalogItemContext({
    required this.id,
    required this.data,
    required this.buildContext,
    this.onDispatchEvent,
    this.dataContext,
  });

  void dispatchEvent(UserActionEvent event) {
    onDispatchEvent?.call(event);
  }
}

/// Definition of a custom catalog item.
class CatalogItem {
  final String name;
  final Schema dataSchema;
  final Widget Function(CatalogItemContext context) widgetBuilder;

  const CatalogItem({
    required this.name,
    required this.dataSchema,
    required this.widgetBuilder,
  });
}

/// Catalog containing registered items.
class Catalog {
  final List<CatalogItem> items;
  final List<ClientFunction> functions;

  const Catalog({
    this.items = const [],
    this.functions = const [],
  });

  Catalog copyWith({
    List<CatalogItem>? newItems,
    List<ClientFunction>? newFunctions,
  }) {
    return Catalog(
      items: [
        ...items,
        if (newItems != null) ...newItems,
      ],
      functions: [
        ...functions,
        if (newFunctions != null) ...newFunctions,
      ],
    );
  }
}

/// Base catalog items factory.
class BasicCatalogItems {
  static Catalog asNoAssetCatalog() => const Catalog();
}
