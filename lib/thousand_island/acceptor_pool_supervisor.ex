defmodule ThousandIsland.AcceptorPoolSupervisor do
  @moduledoc false

  use Supervisor

  @spec start_link({server_pid :: pid, ThousandIsland.ServerConfig.t()}) :: Supervisor.on_start()
  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg)
  end

  @spec acceptor_supervisor_pids(Supervisor.supervisor()) :: [pid()]
  def acceptor_supervisor_pids(supervisor) do
    supervisor
    |> Supervisor.which_children()
    |> Enum.reduce([], fn
      {_, acceptor_pid, _, _}, acc when is_pid(acceptor_pid) -> [acceptor_pid | acc]
      _, acc -> acc
    end)
  end

  @impl Supervisor
  @spec init({server_pid :: pid, ThousandIsland.ServerConfig.t()}) ::
          {:ok,
           {Supervisor.sup_flags(),
            [Supervisor.child_spec() | (old_erlang_child_spec :: :supervisor.child_spec())]}}
  def init({server_pid, %ThousandIsland.ServerConfig{num_acceptors: num_acceptors} = config}) do
    base_spec = {ThousandIsland.AcceptorSupervisor, {server_pid, config}}

    1..num_acceptors
    |> Enum.map(&Supervisor.child_spec(base_spec, id: "acceptor-#{&1}"))
    |> Supervisor.init(strategy: :one_for_one)
  end
end
