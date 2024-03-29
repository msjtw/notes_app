import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:list_split/providers/authprovider.dart';
import 'package:list_split/providers/firestore_provider.dart';
import 'package:list_split/services/expandable_FAB.dart';
import 'package:list_split/services/models/firestore_models.dart';
import 'package:list_split/services/prompts/add_user_prompt.dart';
import 'package:list_split/services/prompts/group_name_prompt.dart';
import 'package:list_split/views/auth_views/login_view.dart';
import 'package:list_split/views/group_view.dart';

import '../services/bnb.dart';

class AuthStateCheck extends ConsumerWidget {
  const AuthStateCheck({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) return SocialView(user);
        return const LoginView();
      },
      error: (error, stackTrace) => const LoginView(),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class SocialView extends ConsumerStatefulWidget {
  const SocialView(this.user, {super.key});

  final User user;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SocialViewState();
}

class _SocialViewState extends ConsumerState<SocialView> {
  @override
  Widget build(BuildContext context) {
    final groupList = ref.watch(userGroupsProvider(widget.user.uid));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your groups'),
        actions: [
          IconButton(
              onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Your account'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("You're logged as: \n${widget.user.email}"),
                          const Text("Do you want to log out?"),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Yes'),
                        ),
                      ],
                    ),
                  ).then((res) {
                    if (res == true) {
                      ref.read(firebaseAuthProvider).signOut();
                    }
                  }),
              icon: const Icon(Icons.logout))
        ],
      ),
      bottomNavigationBar: const BNB(),
      floatingActionButton: ExpandableFab(
        distance: 100.0,
        children: [
          ActionButton(
            onPressed: () async {
              groupNameChange(context, Group(usersUids: [widget.user.uid]))
                  .then(
                (group) {
                  if (group != null) {
                    ref.read(firestoreProvider).addNewGroup(group).catchError(
                      (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e)),
                        );
                        return false;
                      },
                    );
                  }
                },
              );
            },
            icon: const Icon(Icons.add),
          ),
          ActionButton(
            onPressed: () async {
              getGroupUidPrompt(context).then((uid) {
                if (uid != null) {
                  ref
                      .read(firestoreProvider)
                      .addUserToGroup(widget.user, uid)
                      .catchError(
                    (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                      return false;
                    },
                  );
                }
              });
            },
            icon: const Icon(Icons.person_add),
          ),
        ],
      ),
      body: groupList.when(
        data: (data) {
          return ListView.builder(
              itemCount: data.docs.length,
              itemBuilder: (BuildContext context, int index) {
                return groupWidget(context, data.docs[index].data());
              });
        },
        error: (error, stackTrace) => const Center(
          child: Text('Uh oh. Something went wrong!'),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget groupWidget(BuildContext context, Group group) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 8, 8, 0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GroupView(group.uid),
            ),
          );
        },
        onDoubleTap: () async {
          await Clipboard.setData(ClipboardData(text: group.uid)).then(
            (value) => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('uid copied'),
              ),
            ),
          );
        },
        onLongPress: () {
          groupNameChange(context, group).then(
            (group) {
              if (group != null) {
                ref.read(firestoreProvider).addNewGroup(group);
              }
            },
          );
        },
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            color: Colors.grey,
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  ),
                ),
                const SizedBox(height: 10),
                (group.description.isNotEmpty
                    ? Column(
                        children: [
                          Text(
                            group.description,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 10),
                        ],
                      )
                    : Container()),
                Text(
                    '${group.usersUids.length} user${group.usersUids.length == 1 ? '' : 's'}')
              ],
            ),
          ),
        ),
      ),
    );
  }
}
