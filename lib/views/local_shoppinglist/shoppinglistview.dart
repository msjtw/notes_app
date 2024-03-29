import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:list_split/services/prompts/you_sure_prompt.dart';

import '../../providers/shoppinglistprovider.dart';
import '../../services/datestring.dart';
import '../../services/models/objectbox_models.dart';
import 'shoppingview.dart';

class ShoppingListView extends ConsumerStatefulWidget {
  final int uuid;

  const ShoppingListView({required this.uuid, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ShoppingListViewState();
}

class _ShoppingListViewState extends ConsumerState<ShoppingListView> {
  int editUuid = -1;
  bool showHistory = false;

  final _newThingController = TextEditingController();
  final _descriptionChangeController = TextEditingController();

  late FocusNode _thingEditNode;

  @override
  void initState() {
    super.initState();

    _thingEditNode = FocusNode();
  }

  @override
  void dispose() {
    _newThingController.dispose();
    _descriptionChangeController.dispose();
    _thingEditNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return showHistory ? historyView(context) : thingView(context);
  }

  Future<void> _descriptionChange(BuildContext context) async {
    final ShoppingList list = ref
        .read(shoppingListsProvider)
        .where((list) => list.uuid == widget.uuid)
        .first;

    if (list.description != 'add description') {
      _descriptionChangeController.text = list.description;
    } else {
      _descriptionChangeController.clear();
    }

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Change description'),
            content: TextField(
              controller: _descriptionChangeController,
              decoration: const InputDecoration(hintText: "add description"),
              onSubmitted: (newDescription) {
                setState(() {
                  Navigator.pop(context);
                  ref.read(shoppingListsProvider.notifier).editList(list);
                });
              },
            ),
          );
        });
  }

  Widget historyView(BuildContext context) {
    final ShoppingList list = ref
        .watch(shoppingListsProvider)
        .where((list) => list.uuid == widget.uuid)
        .first;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('history of list ${list.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            (list.pastShoppings.isEmpty
                ? const Expanded(
                    child:
                        Center(child: Text('You dont have any past shoppings')))
                : Expanded(
                    child: ListView.builder(
                      itemCount: list.pastShoppings.length,
                      itemBuilder: (BuildContext context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(4),
                          child: GestureDetector(
                            onLongPress: () async {
                              await editPrompt(context).then((action) {
                                if (action == 0) {
                                  ref
                                      .read(shoppingListsProvider.notifier)
                                      .removeShopping(
                                          list.pastShoppings[index]);
                                } else if (action == 1) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ShoppingView(
                                        list: list,
                                        pastShopping: list.pastShoppings[index],
                                      ),
                                    ),
                                  );
                                }
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                                color: Colors.amber,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    (list.pastShoppings[index].name == ''
                                        ? Container(
                                            height: 0,
                                          )
                                        : Text(list.pastShoppings[index].name)),
                                    Row(
                                      children: [
                                        Text(dateString(
                                            list.pastShoppings[index].time)),
                                        Flexible(child: Container()),
                                        list.pastShoppings[index].cost != -1
                                            ? Text(
                                                'cost: ${list.pastShoppings[index].cost}')
                                            : Container(),
                                      ],
                                    ),
                                    ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: list
                                            .pastShoppings[index].things.length,
                                        itemBuilder:
                                            (BuildContext context, kndex) {
                                          return Text(list.pastShoppings[index]
                                              .things[kndex].name);
                                        })
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )),
            IconButton(
                onPressed: () => setState(() {
                      showHistory = false;
                    }),
                icon: const Icon(Icons.expand_more))
          ],
        ),
      ),
    );
  }

  Widget thingView(BuildContext context) {
    final ShoppingList list = ref
        .watch(shoppingListsProvider)
        .where((list) => list.uuid == widget.uuid)
        .first;
    return Scaffold(
      appBar: AppBar(
        title: Text(list.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _descriptionChange(context),
              child: Text(
                list.description,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                child: ListView.builder(
                  itemCount: list.things.length,
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      onLongPress: () {
                        setState(() {
                          editUuid = list.things[index].uuid;
                        });
                        _newThingController.text = list.things[index].name;
                        _thingEditNode.requestFocus();
                      },
                      onHorizontalDragEnd: (details) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ShoppingView(
                              list: list.copyWith(),
                              pastShopping: PastShopping(
                                listUuid: list.uuid,
                                things: [
                                  list.things[index].copyWith(bought: true)
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          list.things[index].name,
                          style: TextStyle(
                            backgroundColor: (list.things[index].bought
                                ? Colors.yellow
                                : Colors.transparent),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            IconButton(
                onPressed: () {
                  setState(() {
                    showHistory = true;
                  });
                },
                icon: const Icon(Icons.history)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newThingController,
                    focusNode: _thingEditNode,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'add a new thing',
                    ),
                    onSubmitted: (String text) {
                      setState(() {
                        if (editUuid == -1) {
                          ref.read(shoppingListsProvider.notifier).addThing(
                              list,
                              Thing(
                                  listUuid: list.uuid,
                                  name: text,
                                  bought: false));
                        } else {
                          ref.read(shoppingListsProvider.notifier).editThing(
                                list,
                                list.things
                                    .where((thing) => thing.uuid == editUuid)
                                    .first
                                    .copyWith(name: text, bought: false),
                              );
                        }

                        editUuid = -1;
                      });

                      _newThingController.clear();
                    },
                  ),
                ),
                (editUuid != -1
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            ref
                                .read(shoppingListsProvider.notifier)
                                .removeThing(
                                    list,
                                    list
                                        .things
                                        .where(
                                            (thing) => thing.uuid == editUuid)
                                        .first);
                          });
                          FocusScope.of(context).unfocus();
                          _newThingController.clear();
                          editUuid = -1;
                        },
                        icon: const Icon(Icons.delete))
                    : Container(width: 0))
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<int?> editPrompt(BuildContext context) async {
    return showDialog<int>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Shopping @'),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  await youSure(context).then((sure) {
                    if (sure == true) {
                      Navigator.pop(context, 0);
                    } else {
                      Navigator.pop(context);
                    }
                  });
                },
                icon: const Icon(Icons.delete),
                label: const Text('delete'),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                icon: const Icon(Icons.edit_note),
                label: const Text('edit'),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('back'),
              ),
            ],
          );
        });
  }
}
