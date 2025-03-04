defmodule Codebattle.Tournament.Server do
  use GenServer

  # API
  def start_link(tournament) do
    GenServer.start(__MODULE__, tournament, name: server_name(tournament.id))
  end

  def get_tournament(id) do
    try do
      GenServer.call(server_name(id), :get_tournament)
    catch
      :exit, _reason -> nil
    end
  end

  def reload_from_db(id) do
    GenServer.cast(server_name(id), :reload_from_db)
  end

  def update_tournament(tournament_id, event_type, params) do
    try do
      GenServer.call(server_name(tournament_id), {event_type, params})
    catch
      :exit, _reason ->
        {:error, :no_proc}
    end
  end

  def get_pid(id) do
    :gproc.where(tournament_key(id))
  end

  # SERVER
  def init(tournament) do
    {:ok, %{tournament: tournament}}
  end

  def handle_call(:get_tournament, _from, state) do
    %{tournament: tournament} = state
    {:reply, tournament, state}
  end

  def handle_call({event_type, params}, _from, %{tournament: tournament} = state) do
    %{module: module} = tournament
    new_tournament = apply(module, event_type, [tournament, params])

    broadcast_tournament(new_tournament)
    {:reply, tournament, Map.merge(state, %{tournament: new_tournament})}
  end

  def handle_cast(:reload_from_db, state) do
    %{tournament: tournament} = state
    new_tournament = Codebattle.Tournament.Context.get_from_db!(tournament.id)
    {:noreply, %{state | tournament: new_tournament}}
  end

  def tournament_topic_name(tournament_id), do: "tournament_#{tournament_id}"

  # HELPERS

  defp broadcast_tournament(tournament) do
    CodebattleWeb.Endpoint.broadcast!(
      tournament_topic_name(tournament.id),
      "update_tournament",
      %{tournament: tournament}
    )
  end

  defp server_name(id) do
    {:via, :gproc, tournament_key(id)}
  end

  defp tournament_key(id) do
    {:n, :l, {:tournament, "#{id}"}}
  end
end
