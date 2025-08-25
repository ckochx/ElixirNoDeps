ElixirConf
Version 4: Tight & Punchy Teaser
Hello Cleveland!
Intro CK & JerryTime

You can do a whole lot with just elixir (no deps)
5 slides
SSH and SSH Tunnels
HTTP clients and HTTP Servers.
ETS for caching
Persistent Term for durable fast access storage. (think immutable cache)
Escript and Release for building runnable binaries.

But what if you do need or want a dependency?
We need to evaluate the tradeoffs.
Is it supported (actively) 
Repo abandonment/orphanage is a real issue.
Is it likely to continue to be supported (i.e. is there a corporate sponsor?)
Is it necessary? 
It used to be that this is a conversation you as an engineer would have with a senior engineer and evaluate the tradeoffs.
How do you handle repos that are under supported? 
Do you fork everything? 
And is that better for you? What if you only need ⅓ of the functionality in a dep? 
Another way. 
Now there is an easier way.
🌶️-take incoming
Use an LLM and import the dependency code directly into your codebase.
This is more or less what happened to Timex and Distillery (without an LLM)
Both solved core problems that were unhandled by core elixir in the v0 days.
Over time, gradually in the case of Timex and all at once in the case of Distillery, the functionality in these 2 libraries migrated into the Elixir core. 
Most of the problems that Timex solved very elegantly 5 years ago have moved into core elixir over this time. 

"A good example would be Timex, the popular date/time library in Elixir.
Timex is powerful and covers a huge surface area: parsing/formatting dates in many locales, time zone handling, shifting by arbitrary intervals, interval math, comparisons, durations, calendars, etc.
But in a lot of apps you might only need, say:
    •    Parse an ISO8601 timestamp,
    •    Shift it forward by a few minutes,
    •    Format it back to a human-readable string.
That’s maybe 10% of what Timex does, and the rest (like calendars, natural language parsing, leap second handling, advanced intervals) you’ll never touch.

Now, pulling in Timex as a dependency (which itself pulls in other libraries, adds compilation time, and potential maintenance burden) could feel heavy. Instead, it might be simpler to just have an LLM help you write a few lightweight helper functions around NaiveDateTime / DateTime / Calendar from Elixir’s standard library.
Because Timex solved such a necessary problem it is now a pervasive transient dependency. 
And that is unfortunate since the author, as I understand it, has largely moved on from Elixir. 
Repo abandonment/orphanage is a real issue. Not just in Elixir, but across software engineering. There are fewer open source contributors. There is more disincentive to actually contribute due to both time pressure and social issues…

Modern Problems call for modern solutions
Copy the (open) source in your project directly. 
Leverage an LLM to do this.
Include a reference breadcrumb back to the original. Or cite it directly if your project is also open source.
The old paradigm of writing and maintaining code is dead and dying. Embrace the tools at hand. 
One of the core principals of Elixir is:
Be explicit
Have your code tell you what it does. Don’t rely on indirection or magic.
Well a library is both encapsulation and obfuscation.
Not to suggest that every library is unnecessary. 
Some are very specific or solve a complex problem in a modular fashion, for example postgrex. 
But could you write an app with DB access and not use Ecto? 
Only write SQL? 
Maybe. 
It’s something to consider.
We don’t need to be so dogmatic about how we do software engineering.
There are many paths from here to there and we have entered an age where we can grow the industry and hopefully 
Safer
Thwart supply chain attacks.
Have a smaller code surface area

Callback to the original point about complexity in apps and deployments.
Modern app deployment is too complex. There are too many layers. And the app you write can do most of the things that you are relying on additional layers to handle. 
Talk releases
Distillery
Kubernetes is frankly insane.
Almost no one should use K8s.
Almost no one needs it.
Deploy your elixir code to a single server.
Don’t add anything else until you need to.
Scale the node vertically first (more CPUs/Memory/Resources) 
Only scale horizontally when you need to.
Don’t forget that application clustering is built into the BEAM by default. It’s largely due to the modern abstraction monstrosity that is deployment orchestration (K8s) that you even need a library to manage your elixir clusters in the first place.
At a minimum you should be able to run your whole application from your laptop. (without duplicating all of a multi-service deployment locally)
Unless your company name rhymes with Frugal or Feta.

Dogfood.
This presentation is running in elixir.
It’s code that we had claude reimplement in elixir for this talk.

This talk demo app has no dependencies.

All the code is written in elixir and is part of the app. 

Everything is explicit.



FIN
