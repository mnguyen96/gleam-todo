import argv
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import sqlight

pub fn main() {
  use conn <- sqlight.with_connection("todo.sqlight")
  let sql =
    "
    create table if not exists 'todos' (id integer primary key, task text not null, complete boolean default false)
    "
  let _query = sqlight.exec(sql, conn)

  case argv.load().arguments {
    ["add", ..task] -> add_todo(task |> string.join(" "))
    ["list"] -> list_todos()
    ["complete", id] -> complete_todo(id)
    ["delete", id] -> delete_todo(id)
    _ -> io.println("Usage: add <task>")
  }
}

pub fn add_todo(task: String) {
  use conn <- sqlight.with_connection("todo.sqlight")
  let sql =
    "
    insert into todos (task) values (?)
    "
  let _query =
    sqlight.query(
      sql,
      on: conn,
      with: [sqlight.text(task)],
      expecting: dynamic.bool,
    )
  list_todos()
  io.println("added todo: " <> task)
}

pub fn list_todos() {
  use conn <- sqlight.with_connection("todo.sqlight")
  let query =
    sqlight.query(
      "select id, task, complete from todos",
      on: conn,
      with: [],
      expecting: dynamic.tuple3(dynamic.int, dynamic.string, dynamic.int),
    )
  io.println("ID  COMPLETE TASK")
  list.map(result.unwrap(query, []), fn(x) {
    io.println(
      string.pad_right(int.to_string(x.0), to: 4, with: " ")
      <> case x.2 {
        0 -> "O"
        1 -> "X"
        _ -> "O"
      }
      <> "        "
      <> x.1,
    )
  })
  Nil
}

pub fn complete_todo(id_string: String) {
  use conn <- sqlight.with_connection("todo.sqlight")
  case int.parse(id_string) {
    Ok(formatted_id) -> {
      let _query =
        sqlight.query(
          "Update todos set complete = (true) where id = ?",
          on: conn,
          with: [sqlight.int(formatted_id)],
          expecting: dynamic.int,
        )
      Nil
    }
    Error(_) -> Nil
  }
  list_todos()
}

pub fn delete_todo(id_string: String) -> Nil {
  use conn <- sqlight.with_connection("todo.sqlight")
  case int.parse(id_string) {
    Ok(formatted_id) -> {
      let _query =
        sqlight.query(
          "delete from todos where id = ?",
          on: conn,
          with: [sqlight.int(formatted_id)],
          expecting: dynamic.int,
        )
      Nil
    }
    Error(_) -> Nil
  }
  list_todos()
}
