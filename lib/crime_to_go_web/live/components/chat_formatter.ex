defmodule CrimeToGoWeb.ChatFormatter do
  @moduledoc """
  Formats chat messages with Markdown support and automatic URL detection using MDEx.
  
  Supports:
  - Auto URL detection: https://example.com, http://localhost:4000, www.example.com, example.com
  - Markdown links: [text](url) 
  - Bold: **text** or __text__
  - Italics: *text* or _text_
  
  All links open in a new tab with security attributes and proper HTML sanitization.
  """

  @doc """
  Formats a chat message with Markdown and automatic URL detection, returning safe HTML.
  
  ## Examples
  
      iex> CrimeToGoWeb.ChatFormatter.format_message("Hello **world**!")
      {:safe, "<p>Hello <strong>world</strong>!</p>"}
      
      iex> CrimeToGoWeb.ChatFormatter.format_message("Check [this link](https://example.com)")
      {:safe, "<p>Check <a href=\"https://example.com\" target=\"_blank\" rel=\"noopener noreferrer\">this link</a></p>"}
      
      iex> CrimeToGoWeb.ChatFormatter.format_message("Visit https://google.com for search!")
      {:safe, "<p>Visit <a href=\"https://google.com\" target=\"_blank\" rel=\"noopener noreferrer\">https://google.com</a> for search!</p>"}
  """
  def format_message(content) when is_binary(content) do
    content
    |> String.trim()
    |> MDEx.to_html!(
      extension: [
        autolink: true,
        strikethrough: true
      ],
      parse: [
        relaxed_autolinks: true
      ],
      render: [
        unsafe_: true
      ],
      sanitize: [
        link_rel: "noopener noreferrer"
      ]
    )
    |> post_process_for_chat()
    |> Phoenix.HTML.raw()
  end

  # Post-process the HTML to add target="_blank" and truncate URLs
  defp post_process_for_chat(html) do
    # Pattern to match all <a> tags
    link_pattern = ~r/<a([^>]*href="[^"]*"[^>]*)>([^<]*)<\/a>/
    
    Regex.replace(link_pattern, html, fn _full_match, attributes, link_text ->
      # Add target="_blank" and styling class if not present
      updated_attributes = attributes
        |> add_attribute_if_missing("target", "_blank")
        |> add_attribute_if_missing("class", "underline text-base-content hover:opacity-80")
      
      # Truncate link text if it looks like a URL
      display_text = if String.contains?(link_text, "://") or String.starts_with?(link_text, "www.") do
        truncate_url(link_text, 35)
      else
        link_text
      end
      
      "<a#{updated_attributes}>#{display_text}</a>"
    end)
  end

  # Helper to add attribute if it's not already present
  defp add_attribute_if_missing(attributes, attr_name, attr_value) do
    if String.contains?(attributes, "#{attr_name}=") do
      attributes
    else
      "#{attributes} #{attr_name}=\"#{attr_value}\""
    end
  end

  # Truncate long URLs for display (shorter for chat bubbles)
  defp truncate_url(url, max_length) do
    if String.length(url) > max_length do
      String.slice(url, 0, max_length - 3) <> "..."
    else
      url
    end
  end
end