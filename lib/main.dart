import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

/**TODO -> Future indica que una función va a realizar una operación que puede tardar tiempo y que no bloquea la ejecución del programa*/
/**TODO -> async permite que una función pueda realizar operaciones asíncronas en segundo plano*/
/**TODO -> await indica que se debe esperar a que se complete una operación asíncrona antes de continuar con el siguiente código*/
/**TODO -> Se utiliza típicamente en:
    - Operaciones con bases de datos
    - Llamadas a APIs o servicios web
    - Lectura/escritura de archivos
    - Cualquier operación que pueda tardar tiempo en completarse*/

///
/*-----------------------------------------------------------*/
void main() async {
  // INICIALIZAR SQLITE PARA APLICACIONES DE ESCRITORIO.
  sqfliteFfiInit();
  final databaseFactory = databaseFactoryFfi;

  // CONFIGURAR RUTA DE LA BASE DE DATOS.
  final dbPath = join(await databaseFactory.getDatabasesPath(), 'tasks.db');
  final database = await databaseFactory.openDatabase(dbPath);

  // CREAR TABLA DE TAREAS SI NO EXISTE.
  await database.execute('''
 CREATE TABLE IF NOT EXISTS tasks (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 title TEXT NOT NULL,
 description TEXT NOT NULL,
 completed INTEGER NOT NULL DEFAULT 0)''');
  // INICIAR APLICACIÓN CON BASE DE DATOS.
  runApp(MainApp(database: database));
}

/*-----------------------------------------------------------*/
class MainApp extends StatelessWidget {
  // ATRIBUTO REQUERIDO.
  final Database database;

  // LO ESTABLECEMOS COMO REQUERIDO.
  MainApp({required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // LO PASAMOS COMO PARAMETRO.
      home: HomePage(database: database),
    );
  }
}

/*-----------------------------------------------------------*/
class HomePage extends StatefulWidget {
  // DEBEMOS ESTABLECER AQUI TAMBIEN EL ATRIBUTO REQUERIDO.
  final Database database;

  HomePage({required this.database});

  @override
  State<HomePage> createState() => _HomePageState();
}

/*-----------------------------------------------------------*/
// CLASE PARA ESTABLECER LA ESTRUCTURA DE LA APLICACIÓN
class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _tasks = [];
  final List<String> _dropDownButtonList = ["Completado", "No completado"];

  final _taskTitleController = TextEditingController();
  final _taskDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Función para cargar las tareas desde la base de datos
  Future<void> _loadTasks() async {
    final tasks = await widget.database.query('tasks');
    setState(() {
      _tasks = tasks; // Actualizamos la lista de tareas en el estado
    });
  }

  // Función para añadir una tarea
  Future<void> _addTask(String title, String description) async {
    await widget.database.insert('tasks', {
      'title': title,
      'description': description,
      'completed': 0, // Nueva tarea no está completada
    });
    _taskTitleController.clear();
    _taskDescriptionController.clear();
    _loadTasks(); // Recargamos las tareas después de agregar una
  }

  // Función para cambiar el estado de la tarea (completada o no completada)
  Future<void> _changeTaskStatus(int id, int completed) async {
    await widget.database.update(
      'tasks',
      {'completed': completed}, // Actualizamos el campo 'completed'
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadTasks(); // Recargamos las tareas después de cambiar el estado
  }

  // Función para eliminar una tarea
  Future<void> _deleteTask(int id) async {
    await widget.database.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadTasks(); // Recargamos las tareas después de eliminar una
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tareas", style: TextStyle(fontSize: 40)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Campos para ingresar la tarea
              TextField(
                controller: _taskTitleController,
                decoration: InputDecoration(hintText: 'Nombre de la tarea'),
              ),
              TextField(
                controller: _taskDescriptionController,
                decoration: InputDecoration(hintText: 'Descripción de la tarea'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _addTask(
                    _taskTitleController.text,
                    _taskDescriptionController.text,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  iconColor: Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add),
                    Text("Añadir", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              // Lista de tareas
              Expanded(
                child: ListView.builder(
                  itemCount: _tasks.length,
                  padding: EdgeInsets.all(10),
                  itemBuilder: (context, int index) {
                    final task = _tasks[index];
                    return ListTile(
                      leading: Text(
                        "${task['title']} \n${task['description']}",
                        style: TextStyle(
                          decoration: task['completed'] == 1
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: task['completed'] == 1
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // DropdownButton para cambiar el estado de la tarea
                          DropdownButton<String>(
                            value: task['completed'] == 1 ? "Completado" : "No completado", // Selección basada en el estado de 'completed'
                            items: _dropDownButtonList.map((String item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              // Convertimos el valor del Dropdown en un int para actualizar la base de datos
                              int completedValue = newValue == "Completado" ? 1 : 0;
                              _changeTaskStatus(task['id'], completedValue);
                            },
                          ),
                          IconButton(
                            onPressed: () {
                              _deleteTask(task['id']);
                            },
                            icon: Icon(Icons.delete),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

