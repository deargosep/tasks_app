import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class ChangePwd extends StatelessWidget {
  // Form
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _repeatnewPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  User user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Сменить пароль'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Смена пароля',
                style: Theme.of(context).textTheme.headline4,
              ),
              Card(
                child: Form(
                  key: _form,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        TextFormField(
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Старый пароль',
                          ),
                          controller: _oldPasswordController,
                        ),
                        TextFormField(
                            obscureText: true,
                            decoration:
                                InputDecoration(labelText: 'Новый пароль'),
                            controller: _newPasswordController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Поле не должно быть пустым.>';
                              }
                              if (value == 'weak-password')
                                return 'Слишком слабый пароль';
                              if (value.length < 6)
                                return 'Пароль должен состоять из не менее 6 символов';

                              return null;
                            }),
                        TextFormField(
                          obscureText: true,
                          decoration: InputDecoration(
                              labelText: 'Повторите новый пароль'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Поле не должно быть пустым.>';
                            }
                            if (value != _newPasswordController.text)
                              return 'Пароли не сходятся.';
                            return null;
                          },
                          controller: _repeatnewPasswordController,
                        ),
                        TextButton(
                            onPressed: () {
                              if (_form.currentState.validate()) {
                                checkPwd() async {
                                  String password = _oldPasswordController.text;
                                  EmailAuthCredential credential =
                                      EmailAuthProvider.credential(
                                          email: user.email,
                                          password: password);
                                  try {
                                    await FirebaseAuth.instance.currentUser
                                        .reauthenticateWithCredential(
                                            credential);
                                  } on FirebaseAuthException catch (e) {
                                    if (e.code == 'wrong-password') {
                                      return Future<bool>.value(false);
                                    }
                                  }
                                }

                                Future<bool> pass = checkPwd();
                                if (pass == false) {
                                  final snackBar = SnackBar(
                                      content:
                                          Text('Текущий пароль неверный!'));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
                                } else {
                                  changePwd();
                                  final snackBar =
                                      SnackBar(content: Text('Пароль сменен!'));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
                                  Navigator.pop(context);
                                }
                              }
                            },
                            child: Text('Отправить'))
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ));
  }

  void changePwd() async {
    User user = FirebaseAuth.instance.currentUser;
    String _newPassword = _newPasswordController.text;
    try {
      await user.updatePassword(_newPassword);
      print(_newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('WEAK PASSWORD!');
      }
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    }
  }
}

class CreateTask extends StatefulWidget {
  @override
  _CreateTaskState createState() => _CreateTaskState();
}

class EditProfile extends StatelessWidget {
  final _newnameController = TextEditingController();
  final _newlastnameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Редактировать')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Редактировать профиль',
                style: Theme.of(context).textTheme.headline4),
            Card(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Имя'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Поле не должно быть пустым.>';
                        }
                        return null;
                      },
                      controller: _newnameController,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Фамилия'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Поле не должно быть пустым.>';
                        }
                        return null;
                      },
                      controller: _newlastnameController,
                    ),
                    TextButton(
                        onPressed: () {
                          changeName();
                          final snackBar =
                              SnackBar(content: Text('Профиль обновлен.'));
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                          Navigator.pop(context);
                        },
                        child: Text('Готово'))
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void changeName() async {
    String newname =
        _newnameController.text + ' ' + _newlastnameController.text;
    User user = FirebaseAuth.instance.currentUser;

    try {
      user.updateProfile(
        displayName: newname,
      );
    } on FirebaseAuthException catch (e) {
      print(e.code);
    }
  }
}

class GetData extends StatelessWidget {
  final int status;

  GetData(this.status);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('Tasks')
            .where('status', isEqualTo: status)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            scrollDirection: Axis.vertical,
            physics: ScrollPhysics(),
            padding: EdgeInsets.only(top: 24),
            itemCount: snapshot.data.docs.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              var temp = snapshot.data.docs[index].data();
              var tempId = snapshot.data.docs[index].id;
              return Card(
                  child: ListTile(
                title: Text(
                  temp['name'],
                  style: Theme.of(context).textTheme.headline6,
                ),
                subtitle: Text(temp['author'] + '\n' + tempId),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => WatchTask(
                              temp['name'].toString(),
                              temp['description'].toString(),
                              temp['author'].toString(),
                              temp['status'],
                              tempId)));
                },
              ));
            },
          );
        });
  }
}

class Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: TextButton(
      child: Text('loading...'),
      onPressed: () {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => MyApp()));
      },
    )));
  }
}

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class MyApp extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return MaterialApp(home: SomethingWentWrong());
          }

          if (snapshot.connectionState == ConnectionState.done) {
            User user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              return MaterialApp(home: Login());
            } else {
              print('User is signed in!');
              return MaterialApp(home: MyHomePage());
            }
          }
          return MaterialApp(home: Loading());
        });
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class SomethingWentWrong extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: TextButton(
                child: Text('Something went wrong!'),
                onPressed: () {
                  main();
                })));
  }
}

class WatchTask extends StatelessWidget {
  final String name;
  final String description;
  final String author;
  final int status;
  final String id;

//Edittask
  WatchTask(this.name, this.description, this.author, this.status, this.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
              child: Form(
            child: Column(
              children: [
                ListTile(
                    title: Text(
                      name,
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(description,
                            style: Theme.of(context).textTheme.headline6),
                        Text('Автор: ' + author),
                        Text('id: ' + this.id),
                        Row(
                          children: [
                            Expanded(
                                child: TextButton(
                                    onPressed: () {
                                      changeTask(this.id, 0, context);
                                    },
                                    child: Text('To do'))),
                            Expanded(
                                child: TextButton(
                                    onPressed: () {
                                      changeTask(this.id, 1, context);
                                    },
                                    child: Text('In Progress'))),
                            Expanded(
                                child: TextButton(
                                    onPressed: () {
                                      changeTask(this.id, 2, context);
                                    },
                                    child: Text('Testing'))),
                            Expanded(
                                child: TextButton(
                                    onPressed: () {
                                      changeTask(this.id, 3, context);
                                    },
                                    child: Text('Done'))),
                          ],
                        )
                      ],
                    )),
              ],
            ),
          ))
        ],
      ),
      appBar: AppBar(
        title: Text("Задача"),
      ),
    );
  }

  void changeTask(id, newStatus, context) {
    FirebaseFirestore.instance
        .collection('Tasks')
        .doc(id)
        .update({'status': newStatus})
        .then((value) => print("User Updated"))
        .catchError((error) => print("Failed to update user: $error"));
    Navigator.pop(context);
  }
}

class _CreateTaskState extends State<CreateTask> {
  User user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  final _taskController = TextEditingController();
  final _descriptionController = TextEditingController();

  Future<void> addTask() {
    User user = FirebaseAuth.instance.currentUser;
    String task = _taskController.text;
    String description = _descriptionController.text;
    CollectionReference tasks = FirebaseFirestore.instance.collection('Tasks');
    return tasks
        .add({
          'name': task,
          'description': description,
          'author': user.displayName,
          'status': 0
        })
        .then((value) => print("Task added"))
        .catchError((error) => print("Failed to add task: $error"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Создать задачу"),
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Название'),
                        controller: _taskController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Поле не должно быть пустым.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Описание'),
                        controller: _descriptionController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Поле не должно быть пустым.';
                          }
                          return null;
                        },
                      ),
                      Text('Автор: ' + user.displayName),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState.validate()) {
                            addTask();
                            final snackBar = SnackBar(
                                content: Text('Задача успешно создана.'));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                            Navigator.pop(context);
                          }
                        },
                        child: Text('Создать'),
                      ),
                    ],
                  ),
                ))
          ],
        ),
      ),
    );
  }
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    FirebaseAuth.instance.authStateChanges().listen((User user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
        User user = FirebaseAuth.instance.currentUser;
        print(user);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage()),
        );
      }
    });

    Future _performLogin() async {
      String email = _emailController.text;
      String password = _passwordController.text;
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => MyHomePage()));
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          print('No user found for that email.');
          final snackBar = SnackBar(
              backgroundColor: Colors.red,
              content: Text('Пользователь с такой почтой не найден!'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
        if (e.code == 'wrong-password') {
          final snackBar = SnackBar(
              backgroundColor: Colors.red, content: Text('Неверный пароль!'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          print('Неверный пароль');
        } else if (e.code == 'wrong-password' && e.code == 'user-not-found') {
          final snackBar = SnackBar(
              backgroundColor: Colors.red, content: Text('Ничего не верно'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      }
    }

    User user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text('Login')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Login',
            style: Theme.of(context).textTheme.headline4,
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
                child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Почта'),
                  controller: _emailController,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Пароль'),
                  controller: _passwordController,
                  obscureText: true,
                ),
                TextButton(
                  child: Text('Войти'),
                  onPressed: () {
                    _performLogin();
                  },
                )
              ],
            )),
          ),
          Divider(),
          TextButton(
              child: Text('Создать аккаунт'),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Register()));
              }),
        ],
      ),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    FirebaseAuth.instance.authStateChanges().listen((User user) {
      if (user == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      }
    });
    void logOut() async {
      await FirebaseAuth.instance.signOut();
    }

    _showlogoutDialog() {
      showDialog(
          context: context,
          builder: (_) => new AlertDialog(
                title: new Text("Подтверждение"),
                content: new Text("Вы уверены, что хотите выйти из аккаунта?"),
                actions: <Widget>[
                  TextButton(
                    child: Text('Нет'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('Выйти'),
                    onPressed: () {
                      logOut();
                    },
                  ),
                ],
              ));
    }

    User user = FirebaseAuth.instance.currentUser;

    final List<Widget> _widgetOptions = <Widget>[
      DefaultTabController(
        length: 4,
        child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: TabBar(tabs: [
                Tab(
                  child: Text('To Do'),
                ),
                Tab(
                  child: Text('In Progress'),
                ),
                Tab(
                  child: Text('Testing'),
                ),
                Tab(
                  child: Text('Done'),
                ),
              ]),
            ),
            body: TabBarView(
              children: [
                Scaffold(
                    floatingActionButton: FloatingActionButton(
                      child: Icon(Icons.add),
                      onPressed: () {
                        print('show modal');
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CreateTask()),
                        );
                      },
                    ),
                    body: GetData(0)),
                GetData(1),
                GetData(2),
                GetData(3),
              ],
            )),
      ),
      Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView(children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: 10,
              ),
            ],
          ),
          Text(
            'Профиль',
            style: Theme.of(context).textTheme.headline4,
          ),
          SizedBox(
            height: 20,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(13.0),
              child: Column(
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Text(
                              user.displayName ?? 'Имя Фамилия',
                              style: Theme.of(context).textTheme.headline6,
                            ),
                            Text(
                              user.email,
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => EditProfile()));
                          },
                        )
                      ]),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChangePwd()));
                      },
                      child: Text('Сменить пароль'))
                ],
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: 15,
              ),
              TextButton(
                  child: Text('выйти'),
                  onPressed: () {
                    _showlogoutDialog();
                  }),
            ],
          ),
        ]),
      )
    ];

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Задачи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Профиль',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Task app',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}

class _RegisterState extends State<Register> {
  final _nameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordrepeatController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    void _register() async {
      String name = _nameController.text;
      String lastname = _lastnameController.text;
      String email = _emailController.text;
      String password = _passwordController.text;
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        User user = FirebaseAuth.instance.currentUser;

        user.updateProfile(
          displayName: name + ' ' + lastname,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          print('The password provided is too weak.');
        } else if (e.code == 'email-already-in-use') {
          print('The account already exists for that email.');
        }
      } catch (e) {
        print(e);
      }
    }

    return Scaffold(
        appBar: AppBar(title: Text('Регистрация')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Register',
              style: Theme.of(context).textTheme.headline4,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Имя'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Поле не должно быть пустым.>';
                        }
                        return null;
                      },
                      controller: _nameController,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Фамилия'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Поле не должно быть пустым.>';
                        }
                        return null;
                      },
                      controller: _lastnameController,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Почта'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Поле не должно быть пустым.>';
                        }
                        return null;
                      },
                      controller: _emailController,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Пароль'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Поле не должно быть пустым.>';
                        }
                        if (value == 'weak-password')
                          return 'Слишком слабый пароль';
                        if (value.length < 6)
                          return 'Пароль должен состоять из не менее 6 символов';
                        return null;
                      },
                      controller: _passwordController,
                      obscureText: true,
                    ),
                    TextFormField(
                      decoration:
                          InputDecoration(labelText: 'Повторите пароль'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Поле не должно быть пустым.>';
                        }
                        if (value != _passwordController.text)
                          return 'Пароли не сходятся.';
                        return null;
                      },
                      controller: _passwordrepeatController,
                      obscureText: true,
                    ),
                    TextButton(
                      child: Text('Создать'),
                      onPressed: () {
                        _register();
                      },
                    )
                  ],
                ),
              ),
            )
          ],
        ));
  }
}
