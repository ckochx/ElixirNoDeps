defmodule ElixirNoDeps.WebRemoteServer do
  @moduledoc """
  A web server for remote presentation control.

  Allows controlling the terminal presentation from a mobile device while
  the audience sees the presentation in the terminal. The mobile interface
  shows current slide content, speaker notes, and navigation controls.
  """

  @doc """
  Starts the web server on the specified port.
  Default port is 8080.
  """
  def start(port \\ 8080) do
    {:ok, listen_socket} =
      :gen_tcp.listen(port, [
        :binary,
        packet: :raw,
        active: false,
        reuseaddr: true
      ])

    # Get local IP address for user
    local_ip = get_local_ip()
    IO.puts("\n" <> IO.ANSI.bright() <> "🌐 Remote Control Server Started!" <> IO.ANSI.reset())
    IO.puts("📱 Connect your phone to: http://#{local_ip}:#{port}")
    IO.puts("🎯 Audience sees presentation in terminal")
    IO.puts("📝 You'll see speaker notes on your phone\n")

    accept_loop(listen_socket)
  end

  defp accept_loop(listen_socket) do
    {:ok, client_socket} = :gen_tcp.accept(listen_socket)

    # Handle request in a separate process
    spawn(fn -> handle_request(client_socket) end)

    accept_loop(listen_socket)
  end

  defp handle_request(client_socket) do
    case :gen_tcp.recv(client_socket, 0) do
      {:ok, request} ->
        response = build_response(request)
        :gen_tcp.send(client_socket, response)
        :gen_tcp.close(client_socket)

      {:error, _reason} ->
        :gen_tcp.close(client_socket)
    end
  end

  defp build_response(request) do
    # Parse HTTP request
    [request_line | _headers] = String.split(request, "\r\n")
    [method, path, _version] = String.split(request_line, " ", parts: 3)

    case {method, path} do
      {"GET", "/"} ->
        serve_controller_interface()

      {"GET", "/api/status"} ->
        serve_presentation_status()

      {"POST", "/api/next"} ->
        handle_key_press("enter")

      {"POST", "/api/prev"} ->
        handle_key_press("p")

      {"POST", "/api/goto/" <> slide_num} ->
        case Integer.parse(slide_num) do
          # Convert to 0-based index
          {num, ""} -> handle_navigation({:goto_slide, num - 1})
          _ -> serve_error(400, "Invalid slide number")
        end

      {"GET", "/api/current"} ->
        serve_current_slide_info()

      _ ->
        serve_error(404, "Not Found")
    end
  end

  defp serve_controller_interface do
    body = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Presentation Remote Control</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }

            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                min-height: 100vh;
                padding: 20px;
                transition: background 0.5s ease;
            }

            body.slide-warning {
                background: linear-gradient(135deg, #dc3545 0%, #c82333 100%);
            }

            .container {
                max-width: 600px;
                margin: 0 auto;
            }

            .header {
                text-align: center;
                margin-bottom: 30px;
            }

            .header h1 {
                font-size: 2rem;
                margin-bottom: 10px;
            }

            .status-card {
                background: rgba(255, 255, 255, 0.1);
                backdrop-filter: blur(10px);
                border-radius: 15px;
                padding: 25px;
                margin-bottom: 30px;
                border: 1px solid rgba(255, 255, 255, 0.2);
            }

            .slide-info h2 {
                font-size: 1.5rem;
                margin-bottom: 15px;
                color: #ffd700;
            }

            .slide-content {
                background: rgba(0, 0, 0, 0.3);
                padding: 20px;
                border-radius: 10px;
                margin: 15px 0;
                font-family: 'Monaco', 'Consolas', monospace;
                white-space: pre-wrap;
                line-height: 1.4;
            }

            .speaker-notes {
                background: rgba(255, 165, 0, 0.2);
                border-left: 4px solid #ffa500;
                padding: 15px;
                border-radius: 5px;
                margin: 15px 0;
                font-style: italic;
            }

            .speaker-notes h3 {
                color: #ffa500;
                margin-bottom: 10px;
                font-size: 1.1rem;
            }

            .controls {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 15px;
                margin-top: 30px;
            }

            .btn {
                background: rgba(255, 255, 255, 0.2);
                border: 2px solid rgba(255, 255, 255, 0.3);
                color: white;
                padding: 15px 20px;
                border-radius: 10px;
                font-size: 1.1rem;
                font-weight: bold;
                cursor: pointer;
                transition: all 0.3s ease;
                text-align: center;
                text-decoration: none;
                display: flex;
                align-items: center;
                justify-content: center;
                gap: 8px;
            }

            .btn:hover {
                background: rgba(255, 255, 255, 0.3);
                transform: translateY(-2px);
            }

            .btn:active {
                transform: translateY(0);
            }

            .btn-primary {
                background: rgba(76, 175, 80, 0.3);
                border-color: #4caf50;
            }

            .btn-primary:hover {
                background: rgba(76, 175, 80, 0.5);
            }

            .goto-section {
                grid-column: 1 / -1;
                display: flex;
                gap: 10px;
                align-items: center;
            }

            .goto-input {
                flex: 1;
                padding: 12px;
                border: 2px solid rgba(255, 255, 255, 0.3);
                border-radius: 8px;
                background: rgba(255, 255, 255, 0.1);
                color: white;
                font-size: 1.1rem;
                text-align: center;
            }

            .goto-input::placeholder {
                color: rgba(255, 255, 255, 0.7);
            }

            .slide-counter {
                text-align: center;
                font-size: 1.2rem;
                margin: 20px 0;
                font-weight: bold;
            }

            .timing-info {
                background: rgba(0, 0, 0, 0.2);
                padding: 15px;
                border-radius: 8px;
                margin: 15px 0;
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 15px;
                text-align: center;
            }

            .timer {
                color: #ffa500;
                font-weight: bold;
                font-size: 1.1rem;
            }

            .timer-label {
                color: rgba(255, 255, 255, 0.8);
                font-size: 0.9rem;
                margin-bottom: 5px;
            }

            .next-slide-preview {
                background: rgba(0, 0, 0, 0.2);
                border: 2px solid rgba(255, 255, 255, 0.3);
                border-radius: 10px;
                padding: 15px;
                margin: 15px 0;
            }

            .next-slide-preview h3 {
                color: #90EE90;
                margin-bottom: 10px;
                font-size: 1.1rem;
            }

            .next-slide-preview .preview-content {
                background: rgba(0, 0, 0, 0.3);
                padding: 10px;
                border-radius: 5px;
                font-family: 'Monaco', 'Consolas', monospace;
                font-size: 0.9rem;
                line-height: 1.3;
                max-height: 150px;
                overflow-y: auto;
            }

            .loading {
                opacity: 0.7;
                pointer-events: none;
            }

            @media (max-width: 480px) {
                .controls {
                    grid-template-columns: 1fr;
                }

                .goto-section {
                    flex-direction: column;
                }

                .goto-input {
                    width: 100%;
                }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎯 Presentation Remote</h1>
                <p>Control your presentation from anywhere</p>
            </div>

            <div class="status-card">
                <div id="slide-info" class="slide-info">
                    <div class="slide-counter">
                        <span id="current-slide">-</span> / <span id="total-slides">-</span>
                    </div>

                    <h2 id="slide-title">Loading...</h2>

                    <div id="slide-content" class="slide-content">
                        Connecting to presentation...
                    </div>

                    <div id="speaker-notes" class="speaker-notes" style="display: none;">
                        <h3>📝 Speaker Notes</h3>
                        <div id="notes-content"></div>
                    </div>

                    <div class="timing-info">
                        <div>
                            <div class="timer-label">Total Time</div>
                            <div id="total-timer" class="timer">00:00</div>
                        </div>
                        <div>
                            <div class="timer-label">Current Slide</div>
                            <div id="slide-timer" class="timer">00:00</div>
                        </div>
                    </div>

                    <div id="next-slide-preview" class="next-slide-preview" style="display: none;">
                        <h3>🔮 Next Slide Preview</h3>
                        <div class="preview-content">
                            <div id="next-slide-title" style="font-weight: bold; margin-bottom: 8px;"></div>
                            <div id="next-slide-content"></div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="controls">
                <button class="btn" onclick="navigate('prev')" id="prev-btn">
                    ⬅️ Previous
                </button>
                <button class="btn btn-primary" onclick="navigate('next')" id="next-btn">
                    Next ➡️
                </button>

                <div class="goto-section">
                    <input type="number" class="goto-input" id="goto-input" placeholder="Slide #" min="1">
                    <button class="btn" onclick="gotoSlide()" id="goto-btn">
                        🎯 Go To
                    </button>
                </div>
            </div>
        </div>

        <script>
            let currentSlide = 1;
            let totalSlides = 1;
            const SLIDE_WARNING_THRESHOLD = 40; // seconds

            async function updateSlideInfo() {
                try {
                    const response = await fetch('/api/current');
                    const data = await response.json();

                    currentSlide = data.current_slide + 1; // Convert from 0-based
                    totalSlides = data.total_slides;

                    document.getElementById('current-slide').textContent = currentSlide;
                    document.getElementById('total-slides').textContent = totalSlides;
                    document.getElementById('slide-title').textContent = data.title || 'Untitled Slide';
                    document.getElementById('slide-content').textContent = data.content || 'No content';

                    // Update speaker notes
                    const notesEl = document.getElementById('speaker-notes');
                    const notesContent = document.getElementById('notes-content');

                    if (data.speaker_notes && data.speaker_notes.trim()) {
                        notesContent.textContent = data.speaker_notes;
                        notesEl.style.display = 'block';
                    } else {
                        notesEl.style.display = 'none';
                    }

                    // Update timing information
                    if (data.timing) {
                        document.getElementById('total-timer').textContent = formatTime(data.timing.total_time_seconds);
                        document.getElementById('slide-timer').textContent = formatTime(data.timing.current_slide_time_seconds);
                        
                        // Check if we need to show slide timing warning
                        updateSlideTimingWarning(data.timing.current_slide_time_seconds);
                    }

                    // Update next slide preview
                    const nextSlideEl = document.getElementById('next-slide-preview');
                    if (data.next_slide && (data.next_slide.title || data.next_slide.content)) {
                        document.getElementById('next-slide-title').textContent = data.next_slide.title || 'Untitled';
                        document.getElementById('next-slide-content').textContent = data.next_slide.content || 'No content';
                        nextSlideEl.style.display = 'block';
                    } else {
                        nextSlideEl.style.display = 'none';
                    }

                    // Update button states
                    document.getElementById('prev-btn').disabled = currentSlide <= 1;
                    document.getElementById('next-btn').disabled = currentSlide >= totalSlides;

                } catch (error) {
                    console.error('Failed to update slide info:', error);
                    document.getElementById('slide-title').textContent = 'Connection Error';
                    document.getElementById('slide-content').textContent = 'Failed to connect to presentation server.';
                }
            }

            function formatTime(seconds) {
                const mins = Math.floor(seconds / 60);
                const secs = seconds % 60;
                return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
            }

            function updateSlideTimingWarning(currentSlideSeconds) {
                const body = document.body;
                
                if (currentSlideSeconds >= SLIDE_WARNING_THRESHOLD) {
                    // Add warning class for red background
                    if (!body.classList.contains('slide-warning')) {
                        body.classList.add('slide-warning');
                    }
                } else {
                    // Remove warning class to return to normal background
                    body.classList.remove('slide-warning');
                }
            }

            async function navigate(direction) {
                try {
                    document.body.classList.add('loading');
                    await fetch(`/api/${direction}`, { method: 'POST' });
                    
                    // Clear warning immediately on navigation (new slide = fresh timer)
                    document.body.classList.remove('slide-warning');
                    
                    setTimeout(updateSlideInfo, 100); // Small delay for state to update
                } catch (error) {
                    console.error('Navigation failed:', error);
                } finally {
                    document.body.classList.remove('loading');
                }
            }

            async function gotoSlide() {
                const input = document.getElementById('goto-input');
                const slideNum = parseInt(input.value);

                if (isNaN(slideNum) || slideNum < 1 || slideNum > totalSlides) {
                    alert(`Please enter a slide number between 1 and ${totalSlides}`);
                    return;
                }

                try {
                    document.body.classList.add('loading');
                    await fetch(`/api/goto/${slideNum}`, { method: 'POST' });
                    
                    // Clear warning immediately on navigation (new slide = fresh timer)
                    document.body.classList.remove('slide-warning');
                    
                    input.value = '';
                    setTimeout(updateSlideInfo, 100);
                } catch (error) {
                    console.error('Goto failed:', error);
                } finally {
                    document.body.classList.remove('loading');
                }
            }

            // Handle Enter key in goto input
            document.getElementById('goto-input').addEventListener('keypress', function(e) {
                if (e.key === 'Enter') {
                    gotoSlide();
                }
            });

            // Initial load and periodic updates
            updateSlideInfo();
            setInterval(updateSlideInfo, 1000); // Refresh every 1 second for responsive timers
        </script>
    </body>
    </html>
    """

    build_http_response(200, "text/html", body)
  end

  defp serve_current_slide_info do
    case get_current_presentation_info() do
      {:ok, info} ->
        json_response = simple_json_encode(info)
        build_http_response(200, "application/json", json_response)

      {:error, reason} ->
        error_response = simple_json_encode(%{error: reason})
        build_http_response(500, "application/json", error_response)
    end
  end

  defp serve_presentation_status do
    case get_current_presentation_info() do
      {:ok, info} ->
        status = %{
          status: "running",
          current_slide: info.current_slide,
          total_slides: info.total_slides,
          title: info.presentation_title
        }

        json_response = simple_json_encode(status)
        build_http_response(200, "application/json", json_response)

      {:error, _reason} ->
        status = %{status: "no_presentation"}
        json_response = simple_json_encode(status)
        build_http_response(200, "application/json", json_response)
    end
  end

  defp handle_navigation(command) do
    case send_navigation_command(command) do
      :ok ->
        build_http_response(200, "application/json", simple_json_encode(%{status: "success"}))

      :error ->
        build_http_response(
          500,
          "application/json",
          simple_json_encode(%{error: "Navigation failed"})
        )

      :quit ->
        build_http_response(
          200,
          "application/json",
          simple_json_encode(%{status: "presentation_ended"})
        )
    end
  end

  defp handle_key_press(key) do
    case send_key_press(key) do
      :ok ->
        build_http_response(200, "application/json", simple_json_encode(%{status: "success"}))

      :error ->
        build_http_response(
          500,
          "application/json",
          simple_json_encode(%{error: "Navigation failed"})
        )

      :quit ->
        build_http_response(
          200,
          "application/json",
          simple_json_encode(%{status: "presentation_ended"})
        )
    end
  end

  defp serve_error(code, message) do
    body = simple_json_encode(%{error: message})
    build_http_response(code, "application/json", body)
  end

  # Interface with the existing Navigator GenServer
  defp send_navigation_command(command) do
    try do
      case Process.whereis(ElixirNoDeps.Presenter.Navigator) do
        nil ->
          :error

        _pid ->
          ElixirNoDeps.Presenter.Navigator.navigate(command)
      end
    rescue
      _ -> :error
    end
  end

  defp send_key_press(key) do
    try do
      case Process.whereis(ElixirNoDeps.Presenter.Navigator) do
        nil ->
          :error

        _pid ->
          ElixirNoDeps.Presenter.Navigator.simulate_key_press(key)
      end
    rescue
      _ -> :error
    end
  end

  defp get_current_presentation_info do
    try do
      case Process.whereis(ElixirNoDeps.Presenter.Navigator) do
        nil ->
          {:error, "No presentation running"}

        _pid ->
          presentation = ElixirNoDeps.Presenter.Navigator.get_presentation()
          current_slide = ElixirNoDeps.Presenter.Presentation.current_slide(presentation)
          next_slide = ElixirNoDeps.Presenter.Presentation.next_slide_preview(presentation)
          timing_info = ElixirNoDeps.Presenter.Navigator.get_timing_info(presentation)

          info = %{
            current_slide: presentation.current_slide,
            total_slides: ElixirNoDeps.Presenter.Presentation.slide_count(presentation),
            presentation_title: presentation.title,
            title: if(current_slide, do: current_slide.title, else: nil),
            content: if(current_slide, do: current_slide.content, else: nil),
            speaker_notes: if(current_slide, do: current_slide.speaker_notes, else: nil),
            next_slide: %{
              title: if(next_slide, do: next_slide.title, else: nil),
              content: if(next_slide, do: next_slide.content, else: nil)
            },
            timing: %{
              total_time_seconds: timing_info.total_time_seconds,
              current_slide_time_seconds: timing_info.current_slide_time_seconds
            }
          }

          {:ok, info}
      end
    rescue
      error ->
        {:error, "Failed to get presentation info: #{inspect(error)}"}
    end
  end

  defp build_http_response(status_code, content_type, body) do
    status_text =
      case status_code do
        200 -> "OK"
        400 -> "Bad Request"
        404 -> "Not Found"
        500 -> "Internal Server Error"
      end

    content_length = byte_size(body)

    """
    HTTP/1.1 #{status_code} #{status_text}\r
    Content-Type: #{content_type}\r
    Content-Length: #{content_length}\r
    Connection: close\r
    Access-Control-Allow-Origin: *\r
    Access-Control-Allow-Methods: GET, POST, OPTIONS\r
    Access-Control-Allow-Headers: Content-Type\r
    \r
    #{body}
    """
  end

  # Get local IP address for display to user
  defp get_local_ip do
    case :inet.getif() do
      {:ok, interfaces} ->
        # Find the first non-loopback interface
        interfaces
        |> Enum.find(fn {ip, _broadcast, _netmask} ->
          case ip do
            # Skip loopback
            {127, 0, 0, 1} -> false
            # Skip link-local
            {169, 254, _, _} -> false
            # Private networks
            {ip1, _, _, _} when ip1 in [10, 172, 192] -> true
            _ -> false
          end
        end)
        |> case do
          {ip, _broadcast, _netmask} ->
            ip |> Tuple.to_list() |> Enum.join(".")

          nil ->
            "localhost"
        end

      {:error, _} ->
        "localhost"
    end
  end

  # Simple JSON encoder for basic data structures (no external dependencies)
  defp simple_json_encode(data) do
    encode_value(data)
  end

  defp encode_value(nil), do: "null"
  defp encode_value(true), do: "true"
  defp encode_value(false), do: "false"
  defp encode_value(value) when is_number(value), do: to_string(value)

  defp encode_value(value) when is_binary(value) do
    escaped =
      value
      |> String.replace("\\", "\\\\")
      |> String.replace("\"", "\\\"")
      |> String.replace("\n", "\\n")
      |> String.replace("\r", "\\r")
      |> String.replace("\t", "\\t")

    "\"#{escaped}\""
  end

  defp encode_value(value) when is_atom(value), do: encode_value(to_string(value))

  defp encode_value(value) when is_list(value) do
    values = Enum.map(value, &encode_value/1)
    "[#{Enum.join(values, ",")}]"
  end

  defp encode_value(value) when is_map(value) do
    pairs =
      value
      |> Enum.map(fn {k, v} -> "#{encode_value(to_string(k))}:#{encode_value(v)}" end)

    "{#{Enum.join(pairs, ",")}}"
  end

  defp encode_value(value), do: encode_value(inspect(value))
end
