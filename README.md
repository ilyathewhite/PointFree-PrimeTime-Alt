# PointFree-PrimeTime-Alt

A nore efficient approach that doesn't require a global app state of the whole app + app wide reducer + global app UI update on every state change

The key differences from PointFree:

- Information flows from leaf to root instead of from root to leaf, which means that it has to bubble up only to 
the closest level where it's shared, which should be much more efficient (the current PointFree approach triggers an update to the whole app view hierarchy on every state change. The easiest way to confirm this is to set a breakpoint on body property of the root content view and verify that it is hit when computing the nth prime. It's possible that SwiftUI is still able to optimize the actual UI changes, but it's a dangerous assumption and even then could severely hurt performance in a large app due to the computations that it would have to make to find the diff. The only way to tell for sure is to test it in a large app.)

- No global app state that captures the state for everything in the app, so changes in local state representation don't trigger changes in other parts of the code.

- No boilerplate code to translate local actions into global actions
- No boilerplate code for "views" from global state into local state
- The example local states capture much more from the view representation.

These differences may seem as a matter of aesthetic, but they are issues of performance and ease of app maintenance and collaboration in the team. For example, having to edit one file that contains the global app state can easily introduce merge conflicts when multiple people work on the same app.

An important caveat: in this example, there is one part of state that is not captured by the local store:
```
    @State private var isPrimeModalShown = false
```

It's impossible to keep it on the same lavel as the state for `CounterView` because that view gets rebuilt on the shared state changes, so if we follow the reducer model completely, we would have to put this kind of state in the global state, which would mean following the PointFree model. Alternatively, we could treat it as an effect or use @State (which is the simplest approach). For me, this seems to be a good compromise for performance and ease of writing code.

## Other critique

The current PointFree approach doesn't use Swift / SwiftUI features that make it easy for the runtime to optimize performance. @State, @Binding, @EnvironmentObject, as well as Publisher, Future, Subject etc are meant to be used and give the runtime much more context for optimizations. Doing everything by hand may be instructive but is not great for production code (performance, amount of code to write, additional testing).

The reducer pattern seems to be a good fit for the case when each action applies to the state as a whole, but in the case of UI, instead of one stream of actions, there are multiple UI event streams that affect different parts of the state. Combining those streams (using Combine in this case) matches how we think about UI changes much better than applying actions to the whole state. The simplest example of this is calculated properties. Strictly following the reducer pattern hides the relationship of the computed variable to the part of the state that it depends on. A calculated property makes this relationship much more visible. I think that the same applies to multiple UI event streams that affect part of the state.

A pattern that is based on combining UI event streams would be equally functional, leverage a lot of performant and reusable code, and match how we think about UI.
