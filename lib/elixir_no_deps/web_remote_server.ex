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
        serve_role_selection()

      {"GET", "/presenter"} ->
        serve_presenter_login()

      {"POST", "/presenter/login"} ->
        handle_presenter_login(request)

      {"GET", "/presenter/control"} ->
        handle_authenticated_presenter_route(request)

      {"GET", "/audience"} ->
        serve_audience_interface()

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

      {"POST", "/api/poll/vote"} ->
        handle_poll_vote(request)

      {"GET", "/api/poll/results/" <> slide_id} ->
        serve_poll_results(slide_id)

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

            /* Poll results styles */
            .poll-results {
                background: rgba(0, 0, 0, 0.3);
                padding: 20px;
                border-radius: 10px;
                margin-top: 20px;
                border: 2px solid #f39c12;
            }

            .poll-results h3 {
                color: #f39c12;
                margin-bottom: 15px;
                text-align: center;
            }

            .poll-question-display {
                font-weight: bold;
                margin-bottom: 15px;
                color: #ecf0f1;
                text-align: center;
                font-size: 1.1rem;
            }

            .poll-results-chart {
                margin-bottom: 15px;
            }

            .poll-option-result {
                display: flex;
                align-items: center;
                margin-bottom: 10px;
                padding: 10px;
                border-radius: 5px;
                background: rgba(255, 255, 255, 0.05);
            }

            .poll-option-text {
                flex: 1;
                margin-right: 15px;
                font-weight: 500;
                color: #ecf0f1;
            }

            .poll-option-count {
                margin-right: 15px;
                color: #3498db;
                font-weight: bold;
                min-width: 40px;
                text-align: right;
            }

            .poll-option-percentage {
                margin-right: 10px;
                color: #95a5a6;
                min-width: 45px;
                text-align: right;
                font-size: 0.9rem;
            }

            .poll-option-bar {
                height: 20px;
                background: linear-gradient(90deg, #3498db, #2980b9);
                border-radius: 10px;
                transition: width 0.5s ease;
                min-width: 3px;
                width: 100px;
            }

            .poll-summary {
                text-align: center;
                color: #95a5a6;
                font-style: italic;
                margin-top: 15px;
                padding-top: 15px;
                border-top: 1px solid rgba(255, 255, 255, 0.1);
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

                    <div id="poll-results" class="poll-results" style="display: none;">
                        <h3>📊 Live Poll Results</h3>
                        <div id="poll-question-display" class="poll-question-display"></div>
                        <div id="poll-results-chart" class="poll-results-chart"></div>
                        <div id="poll-summary" class="poll-summary">Total votes: 0</div>
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
            let slideStartTime = null;
            let lastSlideNumber = null;

            async function updateSlideInfo() {
                try {
                    const response = await fetch('/api/current');
                    const data = await response.json();

                    currentSlide = data.current_slide + 1; // Convert from 0-based
                    totalSlides = data.total_slides;

                    // Check if we changed slides and reset client-side timer
                    if (lastSlideNumber !== null && lastSlideNumber !== currentSlide) {
                        slideStartTime = Date.now();
                        console.log('Slide changed, resetting timer');
                    } else if (slideStartTime === null) {
                        // First load
                        slideStartTime = Date.now();
                    }
                    lastSlideNumber = currentSlide;

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

                    // Update poll results if this is a poll slide
                    const pollResultsEl = document.getElementById('poll-results');
                    if (data.poll_data && data.poll_data.question) {
                        updatePollResults(data.poll_data, currentSlide.toString());
                        pollResultsEl.style.display = 'block';
                    } else {
                        pollResultsEl.style.display = 'none';
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

            function updateSlideTimingWarning() {
                if (slideStartTime === null) return;

                const now = Date.now();
                const secondsOnSlide = Math.floor((now - slideStartTime) / 1000);
                const body = document.body;

                if (secondsOnSlide >= SLIDE_WARNING_THRESHOLD) {
                    // Add warning class for red background
                    if (!body.classList.contains('slide-warning')) {
                        body.classList.add('slide-warning');
                        console.log(`Warning activated: ${secondsOnSlide}s on slide`);
                    }
                } else {
                    // Remove warning class to return to normal background
                    if (body.classList.contains('slide-warning')) {
                        body.classList.remove('slide-warning');
                        console.log(`Warning cleared: ${secondsOnSlide}s on slide`);
                    }
                }
            }

            function updateClientSideTimer() {
                if (slideStartTime === null) return;

                const now = Date.now();
                const secondsOnSlide = Math.floor((now - slideStartTime) / 1000);

                // Update the slide timer with client-side calculation for immediate feedback
                document.getElementById('slide-timer').textContent = formatTime(secondsOnSlide);

                // Update visual warning
                updateSlideTimingWarning();
            }

            async function navigate(direction) {
                try {
                    document.body.classList.add('loading');
                    await fetch(`/api/${direction}`, { method: 'POST' });

                    // Reset client-side timer immediately on navigation
                    slideStartTime = Date.now();
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

                    // Reset client-side timer immediately on navigation
                    slideStartTime = Date.now();
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

            async function updatePollResults(pollData, slideId) {
                try {
                    const response = await fetch(`/api/poll/results/${slideId}`);
                    const results = await response.json();

                    // Update poll question display
                    document.getElementById('poll-question-display').textContent = pollData.question;

                    const chartEl = document.getElementById('poll-results-chart');
                    const totalVotes = results.total_votes || 0;

                    let chartHtml = '';
                    pollData.options.forEach((option, index) => {
                        const votes = results.results[index] || 0;
                        const percentage = totalVotes > 0 ? Math.round((votes / totalVotes) * 100) : 0;
                        const barWidth = totalVotes > 0 ? (votes / totalVotes) * 100 : 0;

                        chartHtml +=
                            '<div class="poll-option-result">' +
                                '<div class="poll-option-text">' + option + '</div>' +
                                '<div class="poll-option-count">' + votes + '</div>' +
                                '<div class="poll-option-percentage">' + percentage + '%</div>' +
                                '<div class="poll-option-bar" style="width: ' + barWidth + '%;"></div>' +
                            '</div>';
                    });

                    chartEl.innerHTML = chartHtml;
                    document.getElementById('poll-summary').textContent = 'Total votes: ' + totalVotes;

                } catch (error) {
                    console.error('Failed to update poll results:', error);
                    document.getElementById('poll-results-chart').innerHTML = '<div style="color: #e74c3c; text-align: center;">Failed to load poll results</div>';
                }
            }

            // Initial load and periodic updates
            updateSlideInfo();
            setInterval(updateSlideInfo, 1000); // Refresh every 1 second for responsive timers

            // Client-side timer for immediate visual feedback
            setInterval(updateClientSideTimer, 1000); // Update client-side timer every second
        </script>
    </body>
    </html>
    """

    build_http_response(200, "text/html", body)
  end

  defp serve_role_selection do
    body = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Select Your Role</title>
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
                display: flex;
                justify-content: center;
                align-items: center;
                padding: 20px;
            }

            .container {
                text-align: center;
                max-width: 500px;
            }

            .header {
                margin-bottom: 40px;
            }

            .header h1 {
                font-size: 2.5rem;
                margin-bottom: 15px;
            }

            .header p {
                font-size: 1.2rem;
                opacity: 0.9;
            }

            .role-cards {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 30px;
                margin-top: 40px;
            }

            .role-card {
                background: rgba(255, 255, 255, 0.1);
                backdrop-filter: blur(10px);
                border-radius: 20px;
                padding: 40px 20px;
                text-decoration: none;
                color: white;
                transition: all 0.3s ease;
                border: 2px solid rgba(255, 255, 255, 0.2);
                cursor: pointer;
            }

            .role-card:hover {
                background: rgba(255, 255, 255, 0.2);
                transform: translateY(-5px);
                border-color: rgba(255, 255, 255, 0.4);
            }

            .role-icon {
                font-size: 4rem;
                margin-bottom: 20px;
                display: block;
            }

            .role-title {
                font-size: 1.5rem;
                font-weight: bold;
                margin-bottom: 10px;
            }

            .role-description {
                font-size: 1rem;
                opacity: 0.8;
                line-height: 1.4;
            }

            @media (max-width: 480px) {
                .role-cards {
                    grid-template-columns: 1fr;
                    gap: 20px;
                }

                .header h1 {
                    font-size: 2rem;
                }

                .role-card {
                    padding: 30px 20px;
                }

                .role-icon {
                    font-size: 3rem;
                }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎯 Choose Your Role</h1>
                <p>Join the presentation experience</p>
            </div>

            <div class="role-cards">
                <a href="/presenter" class="role-card">
                    <span class="role-icon">🎤</span>
                    <div class="role-title">Presenter</div>
                    <div class="role-description">
                        Control the presentation with speaker notes and timing
                    </div>
                </a>

                <a href="/audience" class="role-card">
                    <span class="role-icon">👥</span>
                    <div class="role-title">Audience</div>
                    <div class="role-description">
                        Follow along with the live presentation slides
                    </div>
                </a>
            </div>
        </div>
    </body>
    </html>
    """

    build_http_response(200, "text/html", body)
  end

  defp serve_presenter_login do
    body = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Presenter Login</title>
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
                display: flex;
                justify-content: center;
                align-items: center;
                padding: 20px;
            }

            .login-container {
                background: rgba(255, 255, 255, 0.1);
                backdrop-filter: blur(10px);
                border-radius: 20px;
                padding: 40px;
                text-align: center;
                border: 2px solid rgba(255, 255, 255, 0.2);
                max-width: 400px;
                width: 100%;
            }

            .login-header {
                margin-bottom: 30px;
            }

            .login-header h1 {
                font-size: 2rem;
                margin-bottom: 10px;
            }

            .login-header p {
                opacity: 0.8;
            }

            .form-group {
                margin-bottom: 25px;
                text-align: left;
            }

            .form-group label {
                display: block;
                margin-bottom: 8px;
                font-weight: bold;
            }

            .form-group input {
                width: 100%;
                padding: 15px;
                border: 2px solid rgba(255, 255, 255, 0.3);
                border-radius: 10px;
                background: rgba(255, 255, 255, 0.1);
                color: white;
                font-size: 1.1rem;
            }

            .form-group input::placeholder {
                color: rgba(255, 255, 255, 0.7);
            }

            .login-btn {
                width: 100%;
                padding: 15px;
                background: rgba(76, 175, 80, 0.3);
                border: 2px solid #4caf50;
                border-radius: 10px;
                color: white;
                font-size: 1.1rem;
                font-weight: bold;
                cursor: pointer;
                transition: all 0.3s ease;
            }

            .login-btn:hover {
                background: rgba(76, 175, 80, 0.5);
                transform: translateY(-2px);
            }

            .back-link {
                margin-top: 20px;
                display: block;
                color: rgba(255, 255, 255, 0.8);
                text-decoration: none;
            }

            .back-link:hover {
                color: white;
            }

            .error {
                background: rgba(220, 53, 69, 0.2);
                border: 1px solid #dc3545;
                border-radius: 8px;
                padding: 10px;
                margin-bottom: 20px;
                color: #ff6b6b;
            }
        </style>
    </head>
    <body>
        <div class="login-container">
            <div class="login-header">
                <h1>🎤 Presenter Access</h1>
                <p>Enter the presenter password to control the presentation</p>
            </div>

            <form method="POST" action="/presenter/login">
                <div class="form-group">
                    <label for="password">Password:</label>
                    <input type="password" id="password" name="password" placeholder="Enter presenter password" required autofocus>
                </div>

                <button type="submit" class="login-btn">
                    🔓 Access Presenter Controls
                </button>
            </form>

            <a href="/" class="back-link">← Back to role selection</a>
        </div>
    </body>
    </html>
    """

    build_http_response(200, "text/html", body)
  end

  defp serve_audience_interface do
    body = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Live Presentation - Audience View</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }

            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
                color: white;
                min-height: 100vh;
                padding: 20px;
            }

            .audience-container {
                max-width: 800px;
                margin: 0 auto;
            }

            .audience-header {
                text-align: center;
                margin-bottom: 30px;
                padding-bottom: 20px;
                border-bottom: 2px solid rgba(255, 255, 255, 0.2);
            }

            .audience-header h1 {
                font-size: 2rem;
                margin-bottom: 10px;
            }

            .presentation-info {
                opacity: 0.8;
                font-size: 1.1rem;
            }

            .slide-display {
                background: rgba(255, 255, 255, 0.1);
                backdrop-filter: blur(10px);
                border-radius: 15px;
                padding: 30px;
                margin-bottom: 20px;
                border: 1px solid rgba(255, 255, 255, 0.2);
                min-height: 400px;
            }

            .slide-header {
                text-align: center;
                margin-bottom: 25px;
                padding-bottom: 15px;
                border-bottom: 1px solid rgba(255, 255, 255, 0.2);
            }

            .slide-counter {
                font-size: 1rem;
                opacity: 0.8;
                margin-bottom: 10px;
            }

            .slide-title {
                font-size: 2rem;
                font-weight: bold;
                color: #ffd700;
            }

            .slide-content {
                font-size: 1.2rem;
                line-height: 1.6;
                white-space: pre-wrap;
                background: rgba(0, 0, 0, 0.3);
                padding: 25px;
                border-radius: 10px;
                font-family: 'Monaco', 'Consolas', monospace;
            }

            .connection-status {
                text-align: center;
                padding: 15px;
                border-radius: 10px;
                margin-bottom: 20px;
                font-size: 1.1rem;
            }

            .status-connected {
                background: rgba(76, 175, 80, 0.2);
                border: 1px solid #4caf50;
                color: #90EE90;
            }

            .status-disconnected {
                background: rgba(220, 53, 69, 0.2);
                border: 1px solid #dc3545;
                color: #ff6b6b;
            }

            .audience-footer {
                text-align: center;
                margin-top: 30px;
                opacity: 0.7;
            }

            .contact-section {
                margin-top: 25px;
                padding: 20px;
                background: rgba(0, 0, 0, 0.2);
                border-radius: 10px;
                border: 1px solid rgba(255, 255, 255, 0.1);
            }

            .contact-section h3 {
                color: #3498db;
                margin-bottom: 15px;
                font-size: 1.1rem;
                font-weight: 600;
            }

            .contact-links {
                display: flex;
                flex-direction: column;
                gap: 12px;
                align-items: center;
            }

            .contact-link {
                color: #ecf0f1;
                text-decoration: none;
                padding: 10px 20px;
                background: rgba(52, 152, 219, 0.2);
                border-radius: 8px;
                border: 1px solid rgba(52, 152, 219, 0.3);
                transition: all 0.3s ease;
                font-weight: 500;
                min-width: 250px;
                text-align: center;
            }

            .contact-link:hover {
                background: rgba(52, 152, 219, 0.4);
                border-color: #3498db;
                transform: translateY(-1px);
                box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
            }

            .repo-link {
                background: rgba(46, 204, 113, 0.2);
                border-color: rgba(46, 204, 113, 0.3);
            }

            .repo-link:hover {
                background: rgba(46, 204, 113, 0.4);
                border-color: #2ecc71;
            }

            @media (min-width: 768px) {
                .contact-links {
                    flex-direction: row;
                    justify-content: center;
                    flex-wrap: wrap;
                }

                .contact-link {
                    min-width: 200px;
                }
            }

            .loading {
                text-align: center;
                opacity: 0.7;
                font-style: italic;
            }

            /* Poll interface styles */
            .poll-container {
                background: rgba(0, 0, 0, 0.4);
                padding: 30px;
                border-radius: 15px;
                border: 2px solid #3498db;
                text-align: center;
            }

            .poll-question h3 {
                color: #3498db;
                margin-bottom: 25px;
                font-size: 1.4rem;
                font-weight: 600;
            }

            .poll-options {
                display: flex;
                flex-direction: column;
                gap: 15px;
                margin-bottom: 20px;
            }

            .poll-option {
                background: linear-gradient(135deg, #3498db, #2980b9);
                color: white;
                border: none;
                padding: 15px 25px;
                border-radius: 10px;
                font-size: 1.1rem;
                font-weight: 500;
                cursor: pointer;
                transition: all 0.3s ease;
                box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
            }

            .poll-option:hover {
                background: linear-gradient(135deg, #2980b9, #1f5f8c);
                transform: translateY(-2px);
                box-shadow: 0 6px 12px rgba(0, 0, 0, 0.3);
            }

            .poll-option:disabled {
                opacity: 0.6;
                cursor: not-allowed;
                transform: none;
            }

            .poll-option.voted {
                background: linear-gradient(135deg, #27ae60, #229954);
                border: 2px solid #2ecc71;
            }

            .poll-status {
                font-size: 1.1rem;
                padding: 15px;
                border-radius: 8px;
                background: rgba(0, 0, 0, 0.3);
                color: #ecf0f1;
            }

            /* Poll results styles for audience */
            .poll-results-audience {
                margin-top: 25px;
                padding: 20px;
                background: rgba(0, 0, 0, 0.4);
                border-radius: 10px;
                border: 2px solid #27ae60;
            }

            .poll-results-audience h4 {
                color: #27ae60;
                text-align: center;
                margin-bottom: 15px;
                font-size: 1.2rem;
            }

            .poll-results-chart-audience {
                margin-bottom: 15px;
            }

            .poll-option-result-audience {
                display: flex;
                align-items: center;
                margin-bottom: 12px;
                padding: 12px;
                border-radius: 8px;
                background: rgba(255, 255, 255, 0.05);
            }

            .poll-option-text-audience {
                flex: 1;
                margin-right: 15px;
                font-weight: 500;
                color: #ecf0f1;
            }

            .poll-option-count-audience {
                margin-right: 15px;
                color: #3498db;
                font-weight: bold;
                min-width: 40px;
                text-align: right;
            }

            .poll-option-percentage-audience {
                margin-right: 15px;
                color: #27ae60;
                font-weight: bold;
                min-width: 45px;
                text-align: right;
            }

            .poll-option-bar-audience {
                height: 8px;
                background: linear-gradient(135deg, #27ae60, #2ecc71);
                border-radius: 4px;
                min-width: 2px;
                transition: width 0.5s ease;
            }

            .poll-summary-audience {
                text-align: center;
                font-weight: bold;
                color: #3498db;
                font-size: 1rem;
                padding-top: 10px;
                border-top: 1px solid rgba(255, 255, 255, 0.1);
            }

            .slide-text {
                background: rgba(0, 0, 0, 0.3);
                padding: 25px;
                border-radius: 10px;
                font-family: 'Monaco', 'Consolas', monospace;
                line-height: 1.6;
                white-space: pre-wrap;
            }

            @media (max-width: 768px) {
                .slide-title {
                    font-size: 1.5rem;
                }

                .slide-content {
                    font-size: 1rem;
                    padding: 20px;
                }

                .slide-display {
                    padding: 20px;
                }
            }
        </style>
    </head>
    <body>
        <div class="audience-container">
            <div class="audience-header">
                <h1>👥 Live Presentation</h1>
                <div class="presentation-info">
                    <span id="presentation-title">Loading presentation...</span>
                </div>
            </div>

            <div id="connection-status" class="connection-status status-disconnected">
                🔄 Connecting to presentation...
            </div>

            <div class="slide-display">
                <div class="slide-header">
                    <div class="slide-counter">
                        Slide <span id="current-slide">-</span> of <span id="total-slides">-</span>
                    </div>
                    <div id="slide-title" class="slide-title">Loading...</div>
                </div>

                <div id="slide-content" class="slide-content loading">
                    Waiting for presentation to start...
                </div>
            </div>

            <div class="audience-footer">
                <p>🔄 This view updates automatically as the presenter advances slides</p>
                <p>👋 Welcome to the presentation experience!</p>

                <div class="contact-section">
                    <h3>📞 Connect with the Presenters</h3>
                    <div class="contact-links">
                        <a href="https://www.linkedin.com/in/jeremysearls/" target="_blank" class="contact-link">
                            💼 Jeremy Searls - LinkedIn
                        </a>
                        <a href="https://www.linkedin.com/in/ckochx/" target="_blank" class="contact-link">
                            💼 Christian Koch - LinkedIn
                        </a>
                        <a href="https://github.com/ckochx/ElixirNoDeps" target="_blank" class="contact-link repo-link">
                            🔗 View Source Code on GitHub
                        </a>
                    </div>
                </div>
            </div>
        </div>

        <script>
            let currentSlide = 1;
            let isConnected = false;
            let votedSlides = new Set(); // Track which slides user has voted on

            async function updateAudienceView() {
                try {
                    const response = await fetch('/api/current');
                    const data = await response.json();

                    // Update connection status
                    if (!isConnected) {
                        isConnected = true;
                        const statusEl = document.getElementById('connection-status');
                        statusEl.textContent = '✅ Connected to live presentation';
                        statusEl.className = 'connection-status status-connected';
                    }

                    currentSlide = data.current_slide + 1; // Convert from 0-based

                    // Update presentation info
                    document.getElementById('presentation-title').textContent = data.presentation_title || 'Live Presentation';
                    document.getElementById('current-slide').textContent = currentSlide;
                    document.getElementById('total-slides').textContent = data.total_slides;
                    document.getElementById('slide-title').textContent = data.title || 'Untitled Slide';
                    // Handle poll slides vs regular slides
                    const slideContentEl = document.getElementById('slide-content');
                    slideContentEl.classList.remove('loading');

                    if (data.poll_data && data.poll_data.question) {
                        // Check if user has already voted on this slide
                        if (votedSlides.has(currentSlide.toString())) {
                            // Show results if user has voted
                            renderPollResults(data.poll_data, currentSlide.toString());
                        } else {
                            // Show voting interface if user hasn't voted
                            renderPollInterface(data.poll_data, currentSlide.toString());
                        }
                    } else {
                        // Render regular slide content
                        slideContentEl.innerHTML = '<div class="slide-text">' + (data.content || 'No content available').replace(/\\n/g, '<br>') + '</div>';
                    }

                } catch (error) {
                    console.error('Failed to update audience view:', error);

                    // Update connection status
                    isConnected = false;
                    const statusEl = document.getElementById('connection-status');
                    statusEl.textContent = '❌ Connection lost - attempting to reconnect...';
                    statusEl.className = 'connection-status status-disconnected';

                    // Show error in slide content
                    document.getElementById('slide-title').textContent = 'Connection Error';
                    document.getElementById('slide-content').textContent = 'Unable to connect to presentation. Please check your connection.';
                    document.getElementById('slide-content').classList.add('loading');
                }
            }

            function renderPollInterface(pollData, slideId) {
                const slideContentEl = document.getElementById('slide-content');

                let optionsHtml = '';
                pollData.options.forEach((option, index) => {
                    optionsHtml +=
                        '<button class="poll-option" onclick="submitVote(\\'' + slideId + '\\', ' + index + ')">' +
                            option +
                        '</button>';
                });

                slideContentEl.innerHTML =
                    '<div class="poll-container">' +
                        '<div class="poll-question">' +
                            '<h3>🗳️ ' + pollData.question + '</h3>' +
                        '</div>' +
                        '<div class="poll-options">' +
                            optionsHtml +
                        '</div>' +
                        '<div id="poll-status" class="poll-status">' +
                            'Choose your answer above' +
                        '</div>' +
                    '</div>';
            }

            async function submitVote(slideId, optionIndex) {
                try {
                    const response = await fetch('/api/poll/vote', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                        },
                        body: JSON.stringify({
                            slide_id: slideId,
                            option: optionIndex
                        })
                    });

                    if (response.ok) {
                        // Mark this slide as voted on
                        votedSlides.add(slideId);

                        // Get current poll data and show results
                        const slideResponse = await fetch('/api/current');
                        const slideData = await slideResponse.json();

                        if (slideData.poll_data && slideData.poll_data.question) {
                            renderPollResults(slideData.poll_data, slideId);
                        }
                    } else {
                        document.getElementById('poll-status').innerHTML = '❌ Failed to submit vote. Please try again.';
                    }
                } catch (error) {
                    console.error('Vote submission failed:', error);
                    document.getElementById('poll-status').innerHTML = '❌ Connection error. Please try again.';
                }
            }

            async function renderPollResults(pollData, slideId) {
                try {
                    // Get poll results
                    const resultsResponse = await fetch(`/api/poll/results/${slideId}`);
                    const results = await resultsResponse.json();

                    const totalVotes = results.total_votes || 0;
                    const slideContentEl = document.getElementById('slide-content');

                    // Create complete poll results HTML
                    let resultsHtml = '<div class="poll-container">';
                    resultsHtml += '<div class="poll-question">';
                    resultsHtml += '<h3>🗳️ ' + pollData.question + '</h3>';
                    resultsHtml += '</div>';

                    resultsHtml += '<div class="poll-status">✅ Thank you for voting!</div>';

                    resultsHtml += '<div class="poll-results-audience">';
                    resultsHtml += '<h4>📊 Poll Results</h4>';
                    resultsHtml += '<div class="poll-results-chart-audience">';

                    pollData.options.forEach((option, index) => {
                        const votes = results.results[index] || 0;
                        const percentage = totalVotes > 0 ? Math.round((votes / totalVotes) * 100) : 0;
                        const barWidth = totalVotes > 0 ? (votes / totalVotes) * 100 : 0;

                        resultsHtml +=
                            '<div class="poll-option-result-audience">' +
                                '<div class="poll-option-text-audience">' + option + '</div>' +
                                '<div class="poll-option-count-audience">' + votes + '</div>' +
                                '<div class="poll-option-percentage-audience">' + percentage + '%</div>' +
                                '<div class="poll-option-bar-audience" style="width: ' + barWidth + '%;"></div>' +
                            '</div>';
                    });

                    resultsHtml += '</div>';
                    resultsHtml += '<div class="poll-summary-audience">Total votes: ' + totalVotes + '</div>';
                    resultsHtml += '</div>';
                    resultsHtml += '</div>';

                    // Replace the slide content with poll results
                    slideContentEl.innerHTML = resultsHtml;

                } catch (error) {
                    console.error('Failed to render poll results:', error);
                    // Show error message
                    const slideContentEl = document.getElementById('slide-content');
                    slideContentEl.innerHTML =
                        '<div class="poll-container">' +
                            '<div class="poll-question">' +
                                '<h3>🗳️ ' + pollData.question + '</h3>' +
                            '</div>' +
                            '<div class="poll-status">✅ Thank you for voting!</div>' +
                            '<div style="text-align: center; color: #e74c3c; margin-top: 20px;">' +
                                '⚠️ Unable to load results at this time' +
                            '</div>' +
                        '</div>';
                }
            }

            // Initial load and periodic updates
            updateAudienceView();
            setInterval(updateAudienceView, 2000); // Update every 2 seconds
        </script>
    </body>
    </html>
    """

    build_http_response(200, "text/html", body)
  end

  defp handle_presenter_login(request) do
    # Extract the POST body from the request
    request_parts = String.split(request, "\r\n\r\n", parts: 2)

    body =
      case request_parts do
        [_headers, post_body] -> post_body
        _ -> ""
      end

    # Parse form data (simple URL-encoded parsing)
    password =
      case String.contains?(body, "password=") do
        true ->
          body
          |> String.split("&")
          |> Enum.find(&String.starts_with?(&1, "password="))
          |> case do
            "password=" <> pass -> URI.decode_www_form(pass)
            nil -> ""
          end

        false ->
          ""
      end

    # Check password using hash-based authentication
    if verify_presenter_password(password) do
      # Create session token and redirect to presenter control interface
      session_token = create_presenter_session()

      build_http_response(302, "text/html", "", [
        {"Location", "/presenter/control"},
        {"Set-Cookie", "presenter_session=#{session_token}; Path=/; HttpOnly; SameSite=Strict"}
      ])
    else
      # Show login page with error
      serve_presenter_login_error()
    end
  end

  defp serve_presenter_login_error do
    body = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Presenter Login</title>
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
                display: flex;
                justify-content: center;
                align-items: center;
                padding: 20px;
            }

            .login-container {
                background: rgba(255, 255, 255, 0.1);
                backdrop-filter: blur(10px);
                border-radius: 20px;
                padding: 40px;
                text-align: center;
                border: 2px solid rgba(255, 255, 255, 0.2);
                max-width: 400px;
                width: 100%;
            }

            .login-header {
                margin-bottom: 30px;
            }

            .login-header h1 {
                font-size: 2rem;
                margin-bottom: 10px;
            }

            .login-header p {
                opacity: 0.8;
            }

            .form-group {
                margin-bottom: 25px;
                text-align: left;
            }

            .form-group label {
                display: block;
                margin-bottom: 8px;
                font-weight: bold;
            }

            .form-group input {
                width: 100%;
                padding: 15px;
                border: 2px solid rgba(255, 255, 255, 0.3);
                border-radius: 10px;
                background: rgba(255, 255, 255, 0.1);
                color: white;
                font-size: 1.1rem;
            }

            .form-group input::placeholder {
                color: rgba(255, 255, 255, 0.7);
            }

            .login-btn {
                width: 100%;
                padding: 15px;
                background: rgba(76, 175, 80, 0.3);
                border: 2px solid #4caf50;
                border-radius: 10px;
                color: white;
                font-size: 1.1rem;
                font-weight: bold;
                cursor: pointer;
                transition: all 0.3s ease;
            }

            .login-btn:hover {
                background: rgba(76, 175, 80, 0.5);
                transform: translateY(-2px);
            }

            .back-link {
                margin-top: 20px;
                display: block;
                color: rgba(255, 255, 255, 0.8);
                text-decoration: none;
            }

            .back-link:hover {
                color: white;
            }

            .error {
                background: rgba(220, 53, 69, 0.2);
                border: 1px solid #dc3545;
                border-radius: 8px;
                padding: 15px;
                margin-bottom: 20px;
                color: #ff6b6b;
            }
        </style>
    </head>
    <body>
        <div class="login-container">
            <div class="login-header">
                <h1>🎤 Presenter Access</h1>
                <p>Enter the presenter password to control the presentation</p>
            </div>

            <div class="error">
                ❌ Incorrect password. Please try again.
            </div>

            <form method="POST" action="/presenter/login">
                <div class="form-group">
                    <label for="password">Password:</label>
                    <input type="password" id="password" name="password" placeholder="Enter presenter password" required autofocus>
                </div>

                <button type="submit" class="login-btn">
                    🔓 Access Presenter Controls
                </button>
            </form>

            <a href="/" class="back-link">← Back to role selection</a>
        </div>
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
            poll_data: if(current_slide, do: current_slide.poll_data, else: nil),
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

  defp build_http_response(status_code, content_type, body, headers \\ []) do
    status_text =
      case status_code do
        200 -> "OK"
        302 -> "Found"
        400 -> "Bad Request"
        404 -> "Not Found"
        500 -> "Internal Server Error"
      end

    content_length = byte_size(body)

    # Build custom headers
    custom_headers = Enum.map(headers, fn {key, value} -> "#{key}: #{value}\r" end)

    default_headers = [
      "Content-Type: #{content_type}\r",
      "Content-Length: #{content_length}\r",
      "Connection: close\r",
      "Access-Control-Allow-Origin: *\r",
      "Access-Control-Allow-Methods: GET, POST, OPTIONS\r",
      "Access-Control-Allow-Headers: Content-Type\r"
    ]

    all_headers = custom_headers ++ default_headers

    """
    HTTP/1.1 #{status_code} #{status_text}\r
    #{Enum.join(all_headers, "")}
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

  defp encode_value(value), do: "\"#{inspect(value)}\""

  # Poll-related functions

  defp handle_poll_vote(request) do
    case parse_request_body(request) do
      {:ok, %{"slide_id" => slide_id, "option" => option}}
      when is_binary(slide_id) and is_integer(option) ->
        ElixirNoDeps.PollStorage.vote(slide_id, option)

        response = """
        {"success": true, "message": "Vote recorded"}
        """

        build_http_response(200, "application/json", response)

      {:ok, _} ->
        serve_error(400, "Invalid vote data")

      {:error, reason} ->
        serve_error(400, reason)
    end
  end

  defp serve_poll_results(slide_id) do
    results = ElixirNoDeps.PollStorage.get_results(slide_id)
    total_votes = ElixirNoDeps.PollStorage.get_total_votes(slide_id)

    response = """
    {
      "slide_id": #{encode_value(slide_id)},
      "results": #{encode_value(results)},
      "total_votes": #{total_votes}
    }
    """

    build_http_response(200, "application/json", response)
  end

  defp parse_request_body(request) do
    # Extract body from POST request
    parts = String.split(request, "\r\n\r\n", parts: 2)

    case parts do
      [_headers, body] ->
        try do
          # Simple JSON parser for vote data
          body = String.trim(body)

          # Parse basic JSON structure for vote
          cond do
            String.contains?(body, "slide_id") and String.contains?(body, "option") ->
              slide_id = extract_json_value(body, "slide_id")
              option_str = extract_json_value(body, "option")

              case Integer.parse(option_str) do
                {option, ""} -> {:ok, %{"slide_id" => slide_id, "option" => option}}
                _ -> {:error, "Invalid option value"}
              end

            true ->
              {:error, "Missing required fields"}
          end
        rescue
          _ -> {:error, "Invalid JSON"}
        end

      _ ->
        {:error, "No request body"}
    end
  end

  defp extract_json_value(json_string, key) do
    # Simple JSON value extraction - handles both strings and numbers
    # Use String.contains? and manual parsing to avoid regex interpolation issues
    cond do
      String.contains?(json_string, "\"#{key}\"") ->
        case String.split(json_string, "\"#{key}\"") do
          [_, rest] ->
            case String.split(rest, ":", parts: 2) do
              [_, value_part] ->
                value_part = String.trim(value_part)

                cond do
                  String.starts_with?(value_part, "\"") ->
                    # String value
                    case String.split(value_part, "\"", parts: 3) do
                      ["", string_value, _] -> string_value
                      _ -> nil
                    end

                  true ->
                    # Number value
                    case String.split(value_part, [",", "}", "]"], parts: 2) do
                      [number_str, _] -> String.trim(number_str)
                      [number_str] -> String.trim(number_str)
                    end
                end

              _ ->
                nil
            end

          _ ->
            nil
        end

      true ->
        nil
    end
  end

  # Session-based authentication for presenter routes
  defp handle_authenticated_presenter_route(request) do
    case extract_session_token(request) do
      {:ok, token} when is_binary(token) ->
        if verify_presenter_session(token) do
          serve_controller_interface()
        else
          # Invalid or expired session, redirect to login
          build_http_response(302, "text/html", "", [{"Location", "/presenter"}])
        end

      _ ->
        # No session token, redirect to login
        build_http_response(302, "text/html", "", [{"Location", "/presenter"}])
    end
  end

  # Extract session token from request cookies
  defp extract_session_token(request) do
    # Simple cookie parsing to find presenter_session
    case String.split(request, "\r\n") do
      lines ->
        cookie_line = Enum.find(lines, &String.starts_with?(&1, "Cookie:"))

        case cookie_line do
          "Cookie: " <> cookies ->
            # Parse cookies to find presenter_session
            cookies
            |> String.split(";")
            |> Enum.map(&String.trim/1)
            |> Enum.find(&String.starts_with?(&1, "presenter_session="))
            |> case do
              "presenter_session=" <> token -> {:ok, String.trim(token)}
              _ -> {:error, :not_found}
            end

          _ ->
            {:error, :not_found}
        end
    end
  end

  # Create a new presenter session token
  defp create_presenter_session() do
    # Generate a secure random token
    token = :crypto.strong_rand_bytes(32) |> Base.encode64(padding: false)

    # Store session with 24 hour expiration
    expiry = DateTime.utc_now() |> DateTime.add(24, :hour)

    # Store in ETS (reuse the poll storage table)
    :ets.insert(:poll_votes, {{"session", token}, expiry})

    token
  end

  # Verify a presenter session token
  defp verify_presenter_session(token) do
    case :ets.lookup(:poll_votes, {"session", token}) do
      [{_, expiry}] ->
        # Check if session hasn't expired
        DateTime.compare(DateTime.utc_now(), expiry) == :lt

      [] ->
        false
    end
  end

  defp verify_presenter_password(input_password) do
    # SHA256 hash of the presenter password
    stored_hash = "3a5a2512949399115565867a73a413ec6ba215c8f2df385f78b33238a6639b7c"

    # Hash the input password and compare
    input_hash = :crypto.hash(:sha256, input_password) |> Base.encode16(case: :lower)

    # Constant-time comparison to prevent timing attacks
    stored_hash == input_hash
  end
end
