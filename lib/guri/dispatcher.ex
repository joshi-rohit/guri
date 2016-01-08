defmodule Guri.Dispatcher do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, %{handlers: %{}}}
  end

  @spec register_handler(atom, [String.t]) :: :ok
  def register_handler(module, []) do
    :ok
  end
  def register_handler(module, [command_name | tail]) do
    GenServer.call(__MODULE__, {:register_handler, module, command_name})
    register_handler(module, tail)
  end

  @spec handler_for(String.t) :: atom
  def handler_for(command_name) do
    GenServer.call(__MODULE__, {:handler_for, command_name})
  end

  @spec dispatch(Guri.Command.t) :: :ok
  def dispatch(command) do
    GenServer.call(__MODULE__, {:dispatch, command})
  end

  def handle_call({:register_handler, module, command_name}, _from, state) do
    {:reply, :ok, put_in(state.handlers[command_name], module)}
  end
  def handle_call({:handler_for, command_name}, _from, state) do
    {:reply, state.handlers[command_name], state}
  end
  def handle_call({:dispatch, %{name: command_name} = command}, _from, state) do
    handler = state.handlers[command_name]
    dispatch_command(command, handler)
    {:reply, :ok, state}
  end

  @spec dispatch_command(Guri.Command.t, atom) :: :ok
  defp dispatch_command(command, nil) do
    Logger.error("No command handler specified for: #{command.name}")
    :ok
  end
  defp dispatch_command(command, handler) do
    Logger.error("Dispatching command: #{command.name}")
    handler.handle_command(command)
    :ok
  end
end
