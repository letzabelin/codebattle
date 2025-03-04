defmodule Codebattle.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    unless Mix.env() == :prod do
      Envy.load(["../../.env"])
      Envy.reload_config()
    end

    prod_workers =
      if Mix.env() == :prod do
        [
          {Codebattle.DockerLangsPuller, []},
          {Codebattle.TasksImporter, []}
        ]
      else
        []
      end

    children =
      [
        {Codebattle.Repo, []},
        CodebattleWeb.Telemetry,
        {Phoenix.PubSub, [name: :cb_pubsub, adapter: Phoenix.PubSub.PG2]},
        {CodebattleWeb.Presence, []},
        {CodebattleWeb.Endpoint, []},
        {Codebattle.GameProcess.TasksQueuesServer, []},
        {Codebattle.GameProcess.GlobalSupervisor, []},
        {Codebattle.Tournament.GlobalSupervisor, []},
        {Codebattle.InvitesKillerServer, []},
        {Codebattle.Chat.Server, :lobby},
        {Codebattle.Bot.CreatorServer, []},
        {Codebattle.Utils.ContainerGameKiller, []},
        {Codebattle.UsersActivityServer, []},
        {Codebattle.UsersRankUpdateServer, []}
      ] ++ prod_workers

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: __MODULE__,
      max_restarts: 13_579,
      max_seconds: 11
    )
  end

  def config_change(changed, _new, removed) do
    CodebattleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
