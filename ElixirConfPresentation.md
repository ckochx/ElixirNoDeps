# ElixirConf: Building with Zero Dependencies
## A Modern Approach to Elixir Development

---

## Hello Cleveland! 👋

**Christian Koch & Jeremy Searls**

*Let's talk about doing more with less*

---

## The Big Question 🤔

**How much can you build with just Elixir?**

*(No external dependencies)*

---

## Elixir's Hidden Superpowers ⚡

**You already have everything you need:**

- SSH clients & tunnels
- HTTP servers & clients  
- ETS for caching
- Persistent Term for fast storage
- Escript & Release for binaries

---

## SSH in Pure Elixir 🔐

```elixir
# Built-in SSH client
:ssh.connect('example.com', 22, [
  {:user, 'myuser'},
  {:password, 'mypass'}
])

# SSH tunnels? Also built-in!
```

*No Paramiko. No libssh2. Just Elixir.*

---

## HTTP Without Dependencies 🌐

```elixir
# HTTP Server
{:ok, _} = :inets.start(:httpd, [
  port: 8080,
  server_root: "/tmp",
  document_root: "/tmp/htdocs"
])

# HTTP Client
:httpc.request(:get, {'http://example.com', []}, [], [])
```

*Batteries included since day one.*

---

## Caching & Storage 💾

```elixir
# ETS for fast in-memory cache
:ets.new(:my_cache, [:set, :public, :named_table])
:ets.insert(:my_cache, {"key", "value"})

# Persistent Term for immutable globals  
:persistent_term.put(:config, %{timeout: 5000})
```

*Fast, reliable, built-in.*

---

## But What About Dependencies? 🤷‍♂️

**The hard questions we need to ask:**

- Is it actively maintained?
- Will it be supported long-term?
- Do I need ALL of its functionality?
- Is there a corporate sponsor?

---

## The Dependency Dilemma 📦

**Repository abandonment is REAL:**

- Maintainers move on
- Projects get orphaned
- Transitive dependency hell
- Security vulnerabilities linger

*What's your backup plan?*

---

## Case Study: Timex ⏰

**Timex solved critical date/time problems...**

- Powerful parsing & formatting
- Timezone handling
- Complex date math
- Multiple calendars

**...but most apps only need 10% of it**

---

## Timex vs. Standard Library 📊

**What you probably need:**
```elixir
# Parse ISO8601
# Shift by minutes  
# Format to string
```

**What Timex gives you:**
- Natural language parsing
- Leap second handling
- Advanced intervals
- Complex calendar systems
- ...and much more

---

## The Modern Solution 🌶️

**Hot take incoming:**

**Use an LLM to import only what you need**

*Copy the source directly into your codebase*

---

## This Already Happened! 📚

**Historical precedent:**

- **Timex** → DateTime functionality moved to core
- **Distillery** → Releases moved to core

*The community validated this approach*

---

## Modern Problems, Modern Tools 🛠️

**The new paradigm:**

1. Copy relevant source code
2. Use LLM assistance for extraction
3. Include attribution/citation
4. Own your dependencies

---

## Elixir's Core Principle ✨

> **Be explicit**
> 
> *Have your code tell you what it does*

**Libraries can be:**
- Encapsulation ✅
- Obfuscation ❌

---

## Deployment Complexity 🏗️

**Modern deployment is TOO complex:**

- Too many layers
- Over-engineered solutions
- Kubernetes everywhere

**Your Elixir app can do most of this!**

---

## Keep It Simple 🎯

**Start simple:**
- Deploy to single server
- Scale vertically first (more CPU/RAM)
- Use built-in BEAM clustering
- Only add complexity when NEEDED

**Almost no one needs Kubernetes**

---

## Dogfooding 🐕

**This presentation runs in pure Elixir:**

- No dependencies
- All code explicit
- Everything visible
- LLM-assisted implementation

*Walking the walk*

---

## Key Takeaways 🎯

1. **Elixir is incredibly capable out-of-the-box**
2. **Question every dependency**
3. **LLMs can help you extract what you need**
4. **Keep deployments simple**
5. **Own your critical code**

---

## Questions? 🙋‍♂️

**Let's discuss:**
- Dependency strategies
- LLM-assisted development  
- Deployment simplification
- Your experiences

---

## Thank You! 🙏

**Christian Koch & Jeremy Searls**

*Build more with less*

**Slides & Code:** github.com/ckochx/ElixirNoDeps