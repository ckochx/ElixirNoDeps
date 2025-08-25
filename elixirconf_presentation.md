---
title: "ElixirNoDeps: Zero-Dependency Terminal Presentations"
author: "Christian Koch & Jeremy Searls"
theme: "default"
conference: "ElixirConf US 2025"
---

# ![ElixirConf US Logo](priv/assets/Copy of elixirconf-logo-US-03.png)

**August 28-29, 2025 | Orlando, FL**

<!-- Speaker notes: 
[Walk on with confidence, pause, look at audience]
This is our hook slide - pause here to let the audience take in the title and build anticipation
Wait for full attention before proceeding -->

---

# Hello Cleveland! 👋

## Christian Koch & Jeremy Searls

**Co-Presenting: ElixirNoDeps**

![Man Coding](priv/assets/hello-cleveland.png)

<!-- Speaker notes: 
[0:00-0:20] THE HOOK - Deliver with confidence and energy
"I'm going to make a claim that will either get me laughed off this stage… or completely change how you think about backend architecture.
Your Kubernetes cluster. Your microservices mesh. Redis. Message queues. Load balancers. Half your monitoring stack.
[Pause]
They're all solving problems that shouldn't exist in the first place."

Make eye contact, pause after each item for impact -->

---

# You Can Do A LOT With Just Elixir

## No Dependencies Required

![Elixir Applications](priv/assets/elixir-applications.png)

**Let's explore what's possible with pure Elixir/OTP...**

<!-- Speaker notes: 
[0:20-0:45] THE PROBLEM - Build up the complexity narrative
"For decades, we've scaled by piling on complexity. Microservices to handle load. Containers to manage the services. Meshes to manage the containers. Observability to understand the mesh.
We've built skyscrapers of duct tape… and called it 'modern software engineering.'"

Use the image to emphasize the complexity we're about to challenge -->

---

# SSH & SSH Tunnels

## Built-in SSH Support

![SSH & HTTP](priv/assets/tcp-http-ssh.png)

- **SSH client**: `:ssh` module
- **SSH tunnels**: Port forwarding
- **Key management**: Built-in support
- **No external libraries needed!**

<!-- Speaker notes: 
[0:45-1:10] THE CONTRAST - Introduce the alternative
"But what if I told you there's a 30-year-old technology designed from day one to run millions of concurrent processes, self-heal, and scale effortlessly—without the Rube Goldberg machine?"

This slide demonstrates the first example of built-in capabilities. Emphasize "No external libraries needed!" -->

---

# HTTP Clients & HTTP Servers

## Complete HTTP Stack

![Connecting Platforms](priv/assets/connecting-platforms.png)

- **HTTP client**: `:httpc` module
- **HTTP server**: `:httpd` module  
- **SSL/TLS**: Built-in support
- **REST APIs**: Full implementation

<!-- Speaker notes: 
Continue building the case for built-in capabilities. This shows HTTP is not just client OR server - it's BOTH.
Emphasize that these are production-ready modules, not toy implementations -->

---

# ETS for Caching

## High-Performance In-Memory Storage

![In-Memory Cache](priv/assets/in-memory-cache-optimized-storage-woman.png)

- **Lightning fast**: Native Erlang tables
- **Atomic operations**: Built-in concurrency
- **Memory efficient**: Optimized storage
- **No Redis required!**

<!-- Speaker notes: 
[1:10-1:35] THE REVELATION - Connect to real-world success
"That technology is Elixir, built on the Erlang VM—the same platform behind WhatsApp's billions of messages, Discord's real-time chat, and telecom systems that hit nine nines of uptime.
While we were reinventing the wheel with Docker and Kubernetes, telecom solved this in the 80s."

ETS is incredibly powerful - emphasize "No Redis required!" as this often surprises people -->

---

# Persistent Term for Durable Storage

## Fast, Immutable Cache

![State Management](priv/assets/state-management.png)

- **Persistent across restarts**: Built into OTP
- **Immutable by design**: Functional approach
- **Fast access**: Optimized for reads
- **No database needed for simple data!**

<!-- Speaker notes: 
Persistent Term is often overlooked but incredibly useful. This is where you can mention that sometimes you don't need a full database - just fast, durable storage.
"Sometimes the simplest solution is the best solution" -->

---

# Escript & Release for Binaries

## Deployable Applications

![Erlang Platform](priv/assets/erlang.png)

- **Escript**: Single-file executables
- **Release**: Production deployments
- **Hot code swapping**: Runtime updates
- **Self-contained**: No external deps

<!-- Speaker notes: 
[1:35-1:50] THE PROMISE - Set up what's coming
"Today, I'll show you why Elixir isn't just another language—it's a paradigm shift that can replace your entire backend architecture.
Sometimes, the future means going back to fundamentals that actually work."

This slide shows deployment capabilities. Emphasize "Self-contained" - no Docker needed! -->

---

# But What If You DO Need Dependencies?

## We Need to Evaluate Tradeoffs

![Elixir Jar](priv/assets/elixir_jar.png)

**Let's have an honest conversation about dependency management...**

<!-- Speaker notes: 
Transition slide - acknowledge that dependencies aren't always bad, but we need to be smarter about them.
This is where we pivot from "built-in is great" to "dependencies need evaluation" -->

---

# The Reality of Dependencies

## Active Support Questions

- **Is it actively maintained?**
- **Repo abandonment/orphanage is real**
- **Fewer open source contributors**
- **Time pressure and social issues**

## Corporate Sponsorship

- **Is there corporate backing?**
- **Long-term viability assessment**
- **Community health indicators**

<!-- Speaker notes: 
This is where we get real about the dependency landscape. The "repo abandonment/orphanage" point is crucial - this is happening across the industry.
Emphasize that corporate sponsorship isn't always bad - it can mean long-term stability -->

---

# The Dependency Dilemma

## Traditional Engineering Approach

- **Senior engineer consultation required**
- **Tradeoff evaluation meetings**
- **Risk assessment processes**
- **Time-consuming decision making**

## Modern Reality

- **Faster development cycles needed**
- **More complex dependency graphs**
- **Supply chain security concerns**

<!-- Speaker notes: 
Contrast the old way (slow, bureaucratic) with the new reality (fast, complex, insecure).
This sets up the need for a new approach to dependency management -->

---

# Handling Under-Supported Repos

## The Fork Question

- **Do you fork everything?**
- **Is that better for you?**
- **Maintenance burden transfer**
- **What if you only need ⅓ of functionality?**

## The 80/20 Rule

- **Most libraries are over-engineered**
- **You often need just the core features**
- **The rest adds complexity without value**

<!-- Speaker notes: 
The 80/20 rule is key here - most people only use a small fraction of what libraries provide.
"What if you only need ⅓ of functionality?" - this often resonates with developers -->

---

# 🌶️ Modern Problems, Modern Solutions

## Copy the Source Directly

**Use an LLM to import dependency code into your codebase**

- **Selective inclusion**: Only what you need
- **Full control**: No external dependencies
- **Customization**: Adapt to your use case
- **Transparency**: See exactly what you're using

<!-- Speaker notes: 
🌶️ SPICY TAKE INCOMING - This is the controversial but practical solution
"Now there is an easier way. Use an LLM and import the dependency code directly into your codebase."

This is where you'll get some reactions - lean into it! -->

---

# Historical Precedent: Timex & Distillery

## Core Problems → Core Solutions

![Elixir Evolution](priv/assets/elixir-applications.png)

**Both solved core problems that were unhandled by Elixir in the v0 days**

- **Timex**: Date/time functionality gradually migrated to core
- **Distillery**: Release management became built-in
- **Pattern**: Community libraries → Core features

<!-- Speaker notes: 
This provides historical context and shows this isn't a new idea.
"Both solved core problems that were unhandled by Elixir in the v0 days" - this legitimizes the approach -->

---

# The Timex Example

## What You Might Actually Need

```elixir
# Instead of pulling in all of Timex, maybe you just need:
def parse_iso8601(timestamp) do
  # Parse ISO8601 timestamp
end

def shift_minutes(datetime, minutes) do
  # Shift by a few minutes
end

def format_human_readable(datetime) do
  # Format to human-readable string
end
```

**That's maybe 10% of what Timex does!**

<!-- Speaker notes: 
This is the concrete example that makes it real.
"A good example would be Timex, the popular date/time library in Elixir.
Timex is powerful and covers a huge surface area: parsing/formatting dates in many locales, time zone handling, shifting by arbitrary intervals, interval math, comparisons, durations, calendars, etc.
But in a lot of apps you might only need, say:
• Parse an ISO8601 timestamp,
• Shift it forward by a few minutes,
• Format it back to a human-readable string.
That's maybe 10% of what Timex does, and the rest (like calendars, natural language parsing, leap second handling, advanced intervals) you'll never touch."

Show the code, emphasize "That's maybe 10% of what Timex does!" -->

---

# The Orphanage Problem

## Repo Abandonment Reality

- **Timex author largely moved on from Elixir**
- **Fewer open source contributors**
- **More disincentive to contribute**
- **Time pressure and social issues**

## Across Software Engineering

- **Not just an Elixir problem**
- **Industry-wide trend**
- **Corporate consolidation impact**

<!-- Speaker notes: 
This is the harsh reality check.
"Because Timex solved such a necessary problem it is now a pervasive transient dependency. 
And that is unfortunate since the author, as I understand it, has largely moved on from Elixir. 
Repo abandonment/orphanage is a real issue. Not just in Elixir, but across software engineering. There are fewer open source contributors. There is more disincentive to actually contribute due to both time pressure and social issues…"

Make this personal - this affects everyone in the room -->

---

# Modern Solutions for Modern Problems

## Copy Open Source Into Your Project

![Man Coding](priv/assets/man-coding.png)

**Leverage an LLM to do this intelligently**

- **Include reference breadcrumbs back to original**
- **Cite directly if your project is open source**
- **Embrace the tools at hand**

<!-- Speaker notes: 
"Modern Problems call for modern solutions. Copy the (open) source in your project directly. 
Leverage an LLM to do this. Include a reference breadcrumb back to the original. Or cite it directly if your project is also open source."

This addresses the ethical concerns - we're not stealing, we're adapting -->

---

# The Old Paradigm is Dead

## Writing and Maintaining Code

- **Traditional approach**: Write everything from scratch
- **Modern reality**: Leverage existing solutions
- **LLM assistance**: Intelligent code adaptation
- **Selective inclusion**: Only what you need

## Elixir Core Principle

**"Be explicit"** - Have your code tell you what it does

<!-- Speaker notes: 
"The old paradigm of writing and maintaining code is dead and dying. Embrace the tools at hand. 
One of the core principals of Elixir is: Be explicit. Have your code tell you what it does. Don't rely on indirection or magic."

Connect this back to Elixir's philosophy -->

---

# Libraries: Encapsulation vs. Obfuscation

## The Tradeoff

- **Encapsulation**: Hiding complexity
- **Obfuscation**: Hiding what's happening**
- **Transparency**: See the code you're using
- **Control**: Understand your dependencies

## Not Every Library is Unnecessary

- **Postgrex**: Very specific, complex problem
- **Ecto**: Modular database abstraction
- **But could you write SQL directly?**

<!-- Speaker notes: 
"Well a library is both encapsulation and obfuscation. Not to suggest that every library is unnecessary. 
Some are very specific or solve a complex problem in a modular fashion, for example postgrex. 
But could you write an app with DB access and not use Ecto? Only write SQL? Maybe. It's something to consider."

This shows we're not being dogmatic - some libraries are genuinely valuable -->

---

# Deployment Complexity

## Modern App Deployment is Too Complex

![State Management](priv/assets/state-management.png)

**Too many layers, too much complexity**

- **Your app can do most things**
- **Additional layers often unnecessary**
- **Kubernetes is frankly insane**
- **Almost no one should use K8s**

<!-- Speaker notes: 
Callback to the original point about complexity in apps and deployments.
"Modern app deployment is too complex. There are too many layers. And the app you write can do most of the things that you are relying on additional layers to handle."

This is where you can be more direct: "Kubernetes is frankly insane. Almost no one should use K8s." -->

---

# Scale Vertically First

## The Elixir Way

![Erlang Platform](priv/assets/erlang.png)

- **Deploy to a single server first**
- **Scale vertically**: More CPUs/Memory/Resources
- **Only scale horizontally when needed**
- **Application clustering built into BEAM by default**

## Don't Add Complexity Until You Need It

- **Start simple**
- **Grow organically**
- **Avoid premature optimization**

<!-- Speaker notes: 
"Deploy your elixir code to a single server. Don't add anything else until you need to. 
Scale the node vertically first (more CPUs/Memory/Resources). Only scale horizontally when you need to. 
Don't forget that application clustering is built into the BEAM by default. It's largely due to the modern abstraction monstrosity that is deployment orchestration (K8s) that you even need a library to manage your elixir clusters in the first place."

This is the key insight - BEAM already handles clustering -->

---

# Run From Your Laptop

## Minimum Viable Deployment

![Connecting Platforms](priv/assets/connecting-platforms.png)

**You should be able to run your whole application from your laptop**

- **Without duplicating multi-service deployment locally**
- **Single-node operation**
- **Unless your company name rhymes with Frugal or Feta**

<!-- Speaker notes: 
"At a minimum you should be able to run your whole application from your laptop. (without duplicating all of a multi-service deployment locally)"

The "Frugal or Feta" line is a joke about Google/Meta - use it to lighten the mood -->

---

# Dogfooding: This Presentation

## Running in Elixir

![Dogfooding](priv/assets/Dogfooding-970x912.jpg)

**This presentation is running in Elixir**

- **Code that Claude reimplemented in Elixir for this talk**
- **No dependencies**
- **All code written in Elixir**
- **Everything is explicit**

<!-- Speaker notes: 
"Dogfood. This presentation is running in elixir. It's code that we had claude reimplement in elixir for this talk. 
This talk demo app has no dependencies. All the code is written in elixir and is part of the app. Everything is explicit."

This is your proof of concept - you're literally demonstrating the principles while talking about them! -->

---

# The ElixirNoDeps Demo

## Zero Dependencies, Full Functionality

![SSH & HTTP](priv/assets/tcp-http-ssh.png)

**Let's see it in action...**

- **Terminal presentation tool**
- **Image rendering capabilities**
- **HTTP server functionality**
- **All built with pure Elixir**

<!-- Speaker notes: 
This is where you transition to the live demo. The audience has been seeing this tool in action the whole time, but now you can highlight specific features.
"Let's see it in action..." - build anticipation for the demo -->

---

# Live Demo: ElixirNoDeps

## What We Built

- **Terminal presentation tool**
- **HTTP server capabilities**
- **Image processing**
- **Zero external dependencies**

**Everything you see is running in Elixir!**

<!-- Speaker notes: 
During the demo, emphasize each point as you show it:
- Show the terminal presentation (they've been seeing it)
- Show the HTTP server (maybe open the remote control interface)
- Show image processing (the ASCII art generation)
- Emphasize "Zero external dependencies" - this is the key message

Make sure the demo flows naturally from the presentation -->

---

# Key Takeaways

## 1. **You Can Do More Than You Think**
- SSH, HTTP, caching, storage - all built-in
- No external dependencies required

## 2. **Evaluate Dependencies Honestly**
- Active support, corporate backing, necessity
- Consider copying source vs. adding deps

## 3. **Scale Vertically First**
- Start simple, grow organically
- Avoid premature complexity

<!-- Speaker notes: 
Summarize the three main points clearly. This is your conclusion slide.
Emphasize each takeaway - these are the actionable insights you want people to remember.
"Sometimes the future means going back to fundamentals that actually work" -->

---

# Questions & Discussion

## What Would You Like to Explore?

- **Dependency evaluation strategies?**
- **Deployment simplification?**
- **LLM-assisted development?**
- **Elixir/OTP capabilities?**

![Man Coding](priv/assets/man-coding.png)

<!-- Speaker notes: 
Open the floor for questions. Be prepared for:
- Pushback on the "copy source" approach
- Questions about when dependencies ARE appropriate
- Technical questions about the demo
- Deployment strategy questions

This is where you can address concerns and reinforce your points -->

---

# Thank You!

## Christian Koch & Jeremy Searls

**ElixirNoDeps: Zero Dependencies, Infinite Possibilities**

- **GitHub**: github.com/ckochx/ElixirNoDeps
- **Questions?** Let's discuss!
- **Remember**: Be explicit, start simple, scale smart

<!-- Speaker notes: 
End strong with the tagline: "Zero Dependencies, Infinite Possibilities"
This reinforces your main message and gives people something memorable to take away.
"Remember: Be explicit, start simple, scale smart" - this is your call to action -->

---

# Contact & Resources

## Project Links
- **Repository**: github.com/ckochx/ElixirNoDeps
- **This Presentation**: Running live in Elixir!
- **Examples**: All code available on GitHub

## Stay Connected
- **Elixir Forum**: elixirforum.com
- **Elixir Slack**: elixir-lang.slack.com
- **Twitter**: @elixirlang

<!-- Speaker notes: 
Provide clear next steps for people who want to learn more.
Emphasize "This Presentation: Running live in Elixir!" - it's still your proof of concept -->

---

# Final Thoughts

**"Simplicity is the ultimate sophistication"**

ElixirNoDeps proves that powerful tools don't need complex dependencies.

**Modern problems require modern solutions.**

**Thank you for your attention!**

<!-- Speaker notes: 
End with the quote: "Simplicity is the ultimate sophistication"
This ties everything together - you're advocating for simplicity in a complex world.
"Modern problems require modern solutions" - this justifies the LLM approach.
End with confidence and gratitude -->
