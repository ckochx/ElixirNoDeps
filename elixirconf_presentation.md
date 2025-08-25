---
title: "ElixirNoDeps: Zero-Dependency Terminal Presentations"
author: "Christian Koch & Jeremy Searls"
theme: "default"
conference: "ElixirConf US 2025"
---

# ![ElixirConf US Logo](priv/assets/Copy of elixirconf-logo-US-03.png)

**August 28-29, 2025 | Orlando, FL**

---

# Hello Cleveland! 👋

## Christian Koch & Jeremy Searls

**Co-Presenting: ElixirNoDeps**

![Man Coding](priv/assets/man-coding.png)

---

# You Can Do A LOT With Just Elixir

## No Dependencies Required

![Elixir Applications](priv/assets/elixir-applications.png)

**Let's explore what's possible with pure Elixir/OTP...**

---

# SSH & SSH Tunnels

## Built-in SSH Support

![SSH & HTTP](priv/assets/tcp-http-ssh.png)

- **SSH client**: `:ssh` module
- **SSH tunnels**: Port forwarding
- **Key management**: Built-in support
- **No external libraries needed!**

---

# HTTP Clients & HTTP Servers

## Complete HTTP Stack

![Connecting Platforms](priv/assets/connecting-platforms.png)

- **HTTP client**: `:httpc` module
- **HTTP server**: `:httpd` module  
- **SSL/TLS**: Built-in support
- **REST APIs**: Full implementation

---

# ETS for Caching

## High-Performance In-Memory Storage

![In-Memory Cache](priv/assets/in-memory-cache-optimized-storage-woman.png)

- **Lightning fast**: Native Erlang tables
- **Atomic operations**: Built-in concurrency
- **Memory efficient**: Optimized storage
- **No Redis required!**

---

# Persistent Term for Durable Storage

## Fast, Immutable Cache

![State Management](priv/assets/state-management.png)

- **Persistent across restarts**: Built into OTP
- **Immutable by design**: Functional approach
- **Fast access**: Optimized for reads
- **No database needed for simple data!**

---

# Escript & Release for Binaries

## Deployable Applications

![Erlang Platform](priv/assets/erlang.png)

- **Escript**: Single-file executables
- **Release**: Production deployments
- **Hot code swapping**: Runtime updates
- **Self-contained**: No external deps

---

# But What If You DO Need Dependencies?

## We Need to Evaluate Tradeoffs

![Elixir Jar](priv/assets/elixir_jar.png)

**Let's have an honest conversation about dependency management...**

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

---

# 🌶️ Modern Problems, Modern Solutions

## Copy the Source Directly

**Use an LLM to import dependency code into your codebase**

- **Selective inclusion**: Only what you need
- **Full control**: No external dependencies
- **Customization**: Adapt to your use case
- **Transparency**: See exactly what you're using

---

# Historical Precedent: Timex & Distillery

## Core Problems → Core Solutions

![Elixir Evolution](priv/assets/elixir-applications.png)

**Both solved core problems that were unhandled by Elixir in the v0 days**

- **Timex**: Date/time functionality gradually migrated to core
- **Distillery**: Release management became built-in
- **Pattern**: Community libraries → Core features

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

---

# Modern Solutions for Modern Problems

## Copy Open Source Into Your Project

![Man Coding](priv/assets/man-coding.png)

**Leverage an LLM to do this intelligently**

- **Include reference breadcrumbs back to original**
- **Cite directly if your project is open source**
- **Embrace the tools at hand**

---

# The Old Paradigm is Dead

## Writing and Maintaining Code

- **Traditional approach**: Write everything from scratch
- **Modern reality**: Leverage existing solutions
- **LLM assistance**: Intelligent code adaptation
- **Selective inclusion**: Only what you need

## Elixir Core Principle

**"Be explicit"** - Have your code tell you what it does

---

# Libraries: Encapsulation vs. Obfuscation

## The Tradeoff

- **Encapsulation**: Hiding complexity
- **Obfuscation**: Hiding what's happening
- **Transparency**: See the code you're using
- **Control**: Understand your dependencies

## Not Every Library is Unnecessary

- **Postgrex**: Very specific, complex problem
- **Ecto**: Modular database abstraction
- **But could you write SQL directly?**

---

# Deployment Complexity

## Modern App Deployment is Too Complex

![State Management](priv/assets/state-management.png)

**Too many layers, too much complexity**

- **Your app can do most things**
- **Additional layers often unnecessary**
- **Kubernetes is frankly insane**
- **Almost no one should use K8s**

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

---

# Run From Your Laptop

## Minimum Viable Deployment

![Connecting Platforms](priv/assets/connecting-platforms.png)

**You should be able to run your whole application from your laptop**

- **Without duplicating multi-service deployment locally**
- **Single-node operation**
- **Unless your company name rhymes with Frugal or Feta**

---

# Dogfooding: This Presentation

## Running in Elixir

![Dogfooding](priv/assets/Dogfooding-970x912.jpg)

**This presentation is running in Elixir**

- **Code that Claude reimplemented in Elixir for this talk**
- **No dependencies**
- **All code written in Elixir**
- **Everything is explicit**

---

# The ElixirNoDeps Demo

## Zero Dependencies, Full Functionality

![SSH & HTTP](priv/assets/tcp-http-ssh.png)

**Let's see it in action...**

- **Terminal presentation tool**
- **Image rendering capabilities**
- **HTTP server functionality**
- **All built with pure Elixir**

---

# Live Demo: ElixirNoDeps

## What We Built

- **Terminal presentation tool**
- **HTTP server capabilities**
- **Image processing**
- **Zero external dependencies**

**Everything you see is running in Elixir!**

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

---

# Questions & Discussion

## What Would You Like to Explore?

- **Dependency evaluation strategies?**
- **Deployment simplification?**
- **LLM-assisted development?**
- **Elixir/OTP capabilities?**

![Man Coding](priv/assets/man-coding.png)

---

# Thank You!

## Christian Koch & Jeremy Searls

**ElixirNoDeps: Zero Dependencies, Infinite Possibilities**

- **GitHub**: github.com/ckochx/ElixirNoDeps
- **Questions?** Let's discuss!
- **Remember**: Be explicit, start simple, scale smart

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

---

# Final Thoughts

**"Simplicity is the ultimate sophistication"**

ElixirNoDeps proves that powerful tools don't need complex dependencies.

**Modern problems require modern solutions.**

**Thank you for your attention!**
