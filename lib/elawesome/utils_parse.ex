defmodule Utils.Parse do
  @h4cc_github "https://github.com/h4cc/awesome-elixir"

  def repos() do
    {:ok, html} = Utils.get_contents(@h4cc_github)
    blocks = :lists.dropwhile(fn
       ({"h2", _, _}) -> false
       ({"h2", _, _, _}) -> false
       _ -> true
    end, Floki.find(html, ".Box-body > article > *"))
    parse_repos(blocks)
  end

  def repo_ext_info(url) do
    try do
      # Alter URL
      url = String.replace(url, ~r/\.git$/iu, "", global: true)   # Strip .git to suppress redirects
        |> String.replace(~r/\/pull\/\d+/iu, "", global: true)    # Strip /pull part to display correct data

      # Get page contents
      {:ok, html} = Utils.get_contents(url)

      # Get date of last commit
      datetime_str = Floki.find(html, "[itemprop='dateModified'] relative-time") |> Floki.attribute("datetime") |> to_string()

      datetime = if datetime_str === "" do
        # Query commit page if last commit information is not loaded yet
        commit = Floki.find(html, "include-fragment.commit-tease.commit-loader") |> Floki.attribute("src") |> to_string() |> String.split("/") |> Enum.reverse() |>  hd()
        {:ok, html_commit} = Utils.get_contents("#{url}/commit/#{commit}")
        Floki.find(html_commit, "relative-time") |> Floki.attribute("datetime") |> to_string() |> to_datetime()
      else
        to_datetime(datetime_str)
      end

      %RepoExtInfo{
        stars: Floki.find(html, "a.js-social-count") |> Floki.attribute("aria-label") |> to_string() |> String.split(" ") |> hd() |> String.to_integer(),
        last_commit: DateTime.to_date(datetime),
        days_ago: DateTime.diff(DateTime.utc_now(), datetime) / 86400 |> trunc(),
      }
    rescue
      _ -> :not_exists
    end
  end

  # Parse repositories
  defp parse_repos(html_tree) do
    for html_subtree <- split_repos(html_tree) do
      group = %RepoGroup{
        name: Floki.find(html_subtree, "h2") |> Floki.filter_out("a") |> Floki.text([deep: false]),
        description: Floki.find(html_subtree, "p > em") |> Floki.text([deep: false]),
        url: Floki.find(html_subtree, "h2 > a") |> Floki.attribute("href") |> to_string(),
      }
      items = Floki.find(html_subtree, "ul > li") |> Enum.map(&parse_repo/1) |> Enum.filter(&(String.match?(&1.url, ~r/github.com/iu)))
      {group, items}

    end |> Enum.filter(&(elem(&1, 1) !== []))
  end

  # Split HTML tree structure into repository groups (group title / subtitle / repositories)
  defp split_repos(html_tree), do: split_repos(html_tree, [])

  defp split_repos([], acc), do: Enum.reverse(acc)
  defp split_repos([{"h2", _, _} = a, {"p", _, _} = b, {"ul", _, _} = c | tail], acc), do: split_repos(tail, [[a, b, c] | acc])
  defp split_repos([{"h1", _, _} | _tail], acc), do: split_repos([], acc)
  defp split_repos([_h | tail], acc), do: split_repos(tail, acc)

  # Parse repository
  defp parse_repo(html_subtree) do
    link = Floki.find(html_subtree, "a:first-child")
    %Repo{
      name: link |> Floki.text([deep: false]),
      description: Floki.filter_out(html_subtree, "a:first-child") |> Floki.find("li") |> contents() |> Floki.raw_html() |> String.trim_leading(" - "),
      url: link |> Floki.attribute("href") |> to_string(),
    }
  end

  # HTML tree element contents
  defp contents([{_tag, _attrs, content} | _]), do: content

  # Convert datetime
  defp to_datetime(str) do
    {:ok, datetime, _} = DateTime.from_iso8601(str)
    datetime
  end
end
