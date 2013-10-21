Code.require_file "test_helper.exs", __DIR__
Code.require_file "user.exs", __DIR__

defmodule AxterTest do
  use ExUnit.Case

  test "define an actor" do
    user = User.new
    assert(Process.alive? user)
  end

  test "actor has an id" do
    user = User.new
    assert(User.id(user) != nil)
  end

  test "data store" do
    user = User.new
    id = User.id user
    data = Axter.DataStore.retrieve(User, id)
    data_id = Dict.get(data, :id)
    assert(data_id == id)
  end
 
  test "actor is a zombie" do
    user = User.new
    id1 = User.id user
    User.stop user
    dead = !:erlang.is_process_alive(user)
    id2 = User.id user
    still_moving = id1 == id2
    assert(dead && still_moving)
  end

  test "user name attribute" do
    bob = UserWithName.new("bob")
    assert(UserWithName.name(bob) == "bob")
  end

  test "user name attribute settable" do
    bob = UserWithName.new("bob")
    UserWithName.name(bob, "joe")
    assert(UserWithName.name(bob) == "joe")
  end

end
