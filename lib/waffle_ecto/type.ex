defmodule Waffle.Ecto.Type do
  @moduledoc """
  Provides implementation for custom Ecto.Type behaviour.
  """

  require Logger

  def type, do: :string

  @filename_with_timestamp ~r{^(.*)\?(\d+)$}

  def cast(definition, %{file_name: file, updated_at: updated_at}) do
    cast(definition, %{"file_name" => file, "updated_at" => updated_at})
  end

  def cast(_definition, %{"file_name" => file, "updated_at" => updated_at}) do
    {:ok, %{file_name: file, updated_at: updated_at}}
  end

  def cast(definition, args) do
    case definition.store(args) do
      {:ok, file} -> {:ok, %{file_name: file, updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now, :second)}}
      error ->
        Logger.error(inspect(error))
        :error
    end
  end

  def load(_definition, %{file_name: filename} = value) do
    {:ok, value}
  end
  def load(_definition, value) do
    {file_name, gsec} =
      case Regex.match?(@filename_with_timestamp, value) do
        true ->
          [_, file_name, gsec] = Regex.run(@filename_with_timestamp, value)
          {file_name, gsec}
        _ -> {value, nil}
      end

    updated_at = case gsec do
      gsec when is_binary(gsec) ->
        gsec
        |> String.to_integer
        |> :calendar.gregorian_seconds_to_datetime
        |> NaiveDateTime.from_erl!

      _ ->
        nil
    end

    {:ok, %{file_name: file_name, updated_at: updated_at}}
  end

  def dump(_definition, %{file_name: file_name, updated_at: nil}) do
    {:ok, file_name}
  end

  def dump(_definition, %{file_name: file_name, updated_at: updated_at}) do
    gsec = :calendar.datetime_to_gregorian_seconds(NaiveDateTime.to_erl(updated_at))
    {:ok, "#{file_name}?#{gsec}"}
  end

  def dump(definition, %{"file_name" => file_name, "updated_at" => updated_at}) do
    dump(definition, %{file_name: file_name, updated_at: updated_at})
  end
end
