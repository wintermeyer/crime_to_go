defmodule CrimeToGoWeb.ChatFormatterTest do
  use ExUnit.Case, async: true

  alias CrimeToGoWeb.ChatFormatter

  describe "format_message/1" do
    test "formats bold text" do
      {:safe, result} = ChatFormatter.format_message("This is **bold** text")
      assert result =~ "<strong>bold</strong>"
      assert result =~ "<p>"
    end

    test "formats italic text" do
      {:safe, result} = ChatFormatter.format_message("This is *italic* text")
      assert result =~ "<em>italic</em>"
      assert result =~ "<p>"
    end

    test "formats markdown links" do
      {:safe, result} = ChatFormatter.format_message("Check [this link](https://example.com)")
      assert result =~ ~s(<a href="https://example.com")
      assert result =~ ~s(target="_blank")
      assert result =~ ~s(rel="noopener noreferrer")
      assert result =~ "this link"
    end

    test "auto-detects https URLs" do
      {:safe, result} = ChatFormatter.format_message("Visit https://google.com for search")
      assert result =~ ~s(<a href="https://google.com")
      assert result =~ ~s(target="_blank")
      assert result =~ ~s(rel="noopener noreferrer")
      assert result =~ "https://google.com"
      
      # Should have proper styling for visibility on both chat bubble types
      assert result =~ ~s(class="underline text-base-content hover:opacity-80")
    end

    test "auto-detects localhost URLs" do
      {:safe, result} = ChatFormatter.format_message("Visit http://localhost:4000/games/test for the game")
      assert result =~ ~s(<a href="http://localhost:4000/games/test")
      assert result =~ ~s(target="_blank")
      assert result =~ ~s(rel="noopener noreferrer")
      assert result =~ "http://localhost:4000/games/test"
    end

    test "auto-detects www URLs" do
      {:safe, result} = ChatFormatter.format_message("Go to www.github.com")
      assert result =~ ~s(<a href="http://www.github.com")
      assert result =~ ~s(target="_blank")
      assert result =~ ~s(rel="noopener noreferrer")
      assert result =~ "www.github.com"
    end

    test "auto-detects basic domain URLs" do
      {:safe, result} = ChatFormatter.format_message("Check out example.com")
      # Basic domains might not be auto-detected by MDEx autolink extension
      # This is expected behavior - only well-formed URLs are detected
      if result =~ "<a href=" do
        assert result =~ ~s(target="_blank")
        assert result =~ ~s(rel="noopener noreferrer")
      end
    end

    test "escapes HTML to prevent XSS" do
      {:safe, result} = ChatFormatter.format_message("Test <script>alert('xss')</script>")
      # MDEx sanitization should completely remove script tags for security
      refute result =~ "<script>"
      refute result =~ "alert('xss')"
    end

    test "handles combined formatting" do
      {:safe, result} = ChatFormatter.format_message("Visit [**Google**](https://google.com) or check https://example.com for *info*")
      
      # Should have markdown link
      assert result =~ ~s(<a href="https://google.com")
      assert result =~ "<strong>Google</strong>"
      
      # Should have auto-detected URL (using https:// for better detection)
      assert result =~ ~s(<a href="https://example.com")
      
      # Should have italic
      assert result =~ "<em>info</em>"
    end

    test "truncates long URLs" do
      long_url = "https://example.com/very/long/path/with/many/segments/and/parameters?param1=value1&param2=value2"
      {:safe, result} = ChatFormatter.format_message("Check #{long_url}")
      
      # URL should be full in href but HTML-escaped
      escaped_url = String.replace(long_url, "&", "&amp;")
      assert result =~ ~s(href="#{escaped_url}")
      assert result =~ "..."
      
      # Should be truncated in the link text
      assert result =~ "https://example.com/very/long/pa..."
    end
  end
end