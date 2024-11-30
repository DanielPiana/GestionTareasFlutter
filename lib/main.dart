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
  // LISTA PARA ALMACENAR TAREAS
  List<Map<String, dynamic>> _tasks = [];

  final _taskTitleController = TextEditingController();
  final _taskDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // CARGAR LAS TAREAS AL INICIAR LA PANTALLA
    _loadTasks();
  }

  //FUNCIONES PARA MANEJAR LOS DATOS
  Future<void> _loadTasks() async {
    //COGEMOS DE LA BASE DE DATOS LAS TAREAS, 'tasks' SE REFIERE A LA TABLA DE LA BASE DE DATOS
    final tasks = await widget.database
        .query('tasks'); //EQUIVALE A UN SELECT * FROM tasks
    setState(() {
      //IGUALAMOS LA LISTA DE TAREAS QUE INICIALIZAMOS VACÍA A LAS TAREAS DE LA BASE DE DATOS.
      _tasks = tasks;
    });
  }

  Future<void> _addTask(String title, String description) async {
    //INSERTAMOS EN LA TABLA tasks, EN LAS COLUMNAS title,description,completed
    await widget.database.insert(
        'tasks', // TABLA EN LA QUE INSERTAMOS
        {
          'title': title, // 'nombreColumna': ValorQueAñade
          'description': description, // 'nombreColumna': ValorQueAñade
          'completed': 0 // 'nombreColumna': ValorQueAñade
        });
    // LIMPIAMOS EL TEXTO ESCRITO EN LOS TEXTFIELDS
    _taskTitleController.clear();
    _taskDescriptionController.clear();
    // ACTUALIZAMOS LAS TAREAS
    _loadTasks();
  }

  Future<void> _changeTaskStatus(int id, int completed) async {
    await widget.database.update(
      'tasks', // TABLA EN LA QUE INSERTAMOS
      {'completed': completed == 0 ? 1 : 0},
      // SI 'completed' ES 0(NO COMPLETADO) LO CAMBIA A 1(COMPLETADO) Y VICEVERSA
      where: 'id = ?', // ID PARA ESPECIFICAR LA TAREA QUE QUEREMOS CAMBIAR
      whereArgs: [id], // ESTABLECEMOS EL VALOR DEL ? CON EL ID PROPORCIONADO EN LOS PARAMETROS
    );
    // ACTUALIZAMOS LAS TAREAS
    _loadTasks();
  }

  Future<void> _deleteTask(int id) async {
    await widget.database.delete(
        'tasks', // TABLA EN LA QUE BORRAMOS
        where: 'id = ?', // ID PARA ESPECIFICAR LA TAREA QUE QUEREMOS BORRAR
        whereArgs: [id]); // ESTABLECEMOS EL VALOR DEL ? CON EL ID PROPORCIONADO EN LOS PARAMETROS
    _loadTasks();
  }



  //ESTRUCTURA DE LA APLICACION
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
              TextField(
                controller: _taskTitleController,
                decoration: InputDecoration(hintText: 'Nombre de la tarea'),
              ),
              TextField(
                controller: _taskDescriptionController,
                decoration:
                    InputDecoration(hintText: 'Descripción de la tarea'),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                    onPressed: () {
                      _addTask(_taskTitleController.text, _taskDescriptionController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      iconColor: Colors.white,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      //CAMBIA EL TAMAÑO DEL BOTON AL MINIMO POSIBLE
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add),
                        Text(
                          "Añadir",
                          style: TextStyle(color: Colors.white),
                        )
                      ],
                    )),
              ),
              Expanded(
                child: ListView.builder(
                    itemCount: _tasks.length,
                    padding: EdgeInsets.all(10),
                    itemBuilder: (context, int index) {
                      final task = _tasks[index];
                      return ListTile(
                        leading: IconButton(
                          icon: Icon(task['completed'] == 1 ? Icons.check_box : Icons.check_box_outline_blank),
                          onPressed: () {
                            _changeTaskStatus(task['id'], task['completed']);
                          },
                        ),
                        title: Text("${task['title']} \n${task['description']}",
                          style: TextStyle(
                            decoration: task['completed'] == 1
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: task['completed'] == 1
                              ? Colors.grey
                                : Colors.black
                          ),
                        ),
                        trailing: IconButton(
                            onPressed: () {
                              _deleteTask(task['id']);
                            }, icon: const Icon(Icons.delete)),
                      );
                    }),
              )
            ],
          ),
        ),
      ),
    );
  }
}
