This is a web application written using the Phoenix web framework.

## Project guidelines

- Use `mix precommit` alias when you are done with all changes and fix any pending issues
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps

### Phoenix v1.8 guidelines

- **Always** begin your LiveView templates with `<Layouts.app flash={@flash} ...>` which wraps all inner content
- The `MyAppWeb.Layouts` module is aliased in the `my_app_web.ex` file, so you can use it without needing to alias it again
- Anytime you run into errors with no `current_scope` assign:
  - You failed to follow the Authenticated Routes guidelines, or you failed to pass `current_scope` to `<Layouts.app>`
  - **Always** fix the `current_scope` error by moving your routes to the proper `live_session` and ensure you pass `current_scope` as needed
- Phoenix v1.8 moved the `<.flash_group>` component to the `Layouts` module. You are **forbidden** from calling `<.flash_group>` outside of the `layouts.ex` module
- Out of the box, `core_components.ex` imports an `<.icon name="hero-x-mark" class="w-5 h-5"/>` component for hero icons. **Always** use the `<.icon>` component for icons, **never** use `Heroicons` modules or similar
- **Always** use the imported `<.input>` component for form inputs from `core_components.ex` when available. `<.input>` is imported and using it will save steps and prevent errors
- If you override the default input classes (`<.input class="myclass px-2 py-1 rounded-lg">)`) class with your own values, no default classes are inherited, so your
custom classes must fully style the input

### JS and CSS guidelines

- **Use Tailwind CSS classes and custom CSS rules** to create polished, responsive, and visually stunning interfaces.
- Tailwindcss v4 **no longer needs a tailwind.config.js** and uses a new import syntax in `app.css`:

      @import "tailwindcss" source(none);
      @source "../css";
      @source "../js";
      @source "../../lib/my_app_web";

- **Always use and maintain this import syntax** in the app.css file for projects generated with `phx.new`
- **Never** use `@apply` when writing raw css
- **Always** manually write your own tailwind-based components instead of using daisyUI for a unique, world-class design
- Out of the box **only the app.js and app.css bundles are supported**
  - You cannot reference an external vendor'd script `src` or link `href` in the layouts
  - You must import the vendor deps into app.js and app.css to use them
  - **Never write inline <script>custom js</script> tags within templates**

### UI/UX & design guidelines

- **Produce world-class UI designs** with a focus on usability, aesthetics, and modern design principles
- Implement **subtle micro-interactions** (e.g., button hover effects, and smooth transitions)
- Ensure **clean typography, spacing, and layout balance** for a refined, premium look
- Focus on **delightful details** like hover effects, loading states, and smooth page transitions


<!-- usage-rules-start -->

<!-- phoenix:html-start -->
## Phoenix HTML guidelines

- **Always** add unique DOM IDs to key elements (like forms, buttons, etc) when writing templates, these IDs can later be used in tests (`<.form for={@form} id="product-form">`)
- To show literal `{` or `}` in a `<pre>`/`<code>` block, annotate the parent tag with `phx-no-curly-interpolation`. Inside it, dynamic expressions still work with `<%= ... %>`
- HEEx class attrs with multiple values **always** use list `[...]` syntax, and `if`s inside them are wrapped in parens:

      <a class={[
        "px-2 text-white",
        @some_flag && "py-5",
        if(@other_condition, do: "border-red-500", else: "border-blue-100")
      ]}>Text</a>

- Use `{...}` for interpolation in tag attributes and for values in tag bodies. Use `<%= ... %>` **only** for block constructs (if, cond, case, for) within tag bodies. Never use `<%= %>` inside attributes or `{if ...}` / `{end}` in bodies
<!-- phoenix:html-end -->

<!-- phoenix:liveview-start -->
## Phoenix LiveView guidelines

- **Avoid LiveComponent's** unless you have a strong, specific need for them
- LiveViews should be named like `AppWeb.WeatherLive`, with a `Live` suffix. The default `:browser` scope is **already aliased** with the `AppWeb` module, so you can just do `live "/weather", WeatherLive`

### LiveView streams

- **Always** use LiveView streams for collections instead of assigning regular lists (`stream/3`, `stream(..., reset: true)`, `stream(..., at: -1)`, `stream_delete/3`)
- The parent element must set `phx-update="stream"` and a DOM id, and each child uses the stream id as its DOM id:

      <div id="messages" phx-update="stream">
        <div :for={{id, msg} <- @streams.messages} id={id}>
          {msg.text}
        </div>
      </div>

- Streams are *not* enumerable. To filter or refresh, refetch the data and re-stream with `reset: true`
- Streams *do not support counting or empty states*. Track counts in a separate assign. For empty states, use a sibling `<div class="hidden only:block">` as the only other child of the stream container
- When an assign changes content inside streamed items, you MUST re-stream (`stream_insert`) those items along with the updated assign

### LiveView JavaScript interop

- Anytime a `phx-hook` manages its own DOM, you **must** also set `phx-update="ignore"`
- **Always** provide a unique DOM id alongside `phx-hook` otherwise a compiler error will be raised
- **Never** write raw embedded `<script>` tags in HEEx. Use a colocated hook (`:type={Phoenix.LiveView.ColocatedHook}`), whose name **MUST ALWAYS** start with a `.` prefix:

      <input type="text" id="user-phone-number" phx-hook=".PhoneNumber" />
      <script :type={Phoenix.LiveView.ColocatedHook} name=".PhoneNumber">
        export default {
          mounted() { ... }
        }
      </script>

- Colocated hooks are automatically integrated into the app.js bundle. External hooks go in `assets/js/` and are passed to the `LiveSocket` constructor via `hooks: {...}`

### LiveView tests

- Use `Phoenix.LiveViewTest` and `LazyHTML` (included) for assertions
- **Always reference the key element IDs you added in the templates** with `element/2`, `has_element?/2`, etc. **Never** test against raw HTML, and favor element presence over text content
- To debug selector failures, limit output with `LazyHTML`:

      document = LazyHTML.from_fragment(render(view))
      IO.inspect(LazyHTML.filter(document, "your-complex-selector"), label: "Matches")

### Form handling

- **Always** build forms with `to_form/2` assigned in the LiveView (from a changeset, or from string-keyed params with `as:`), and in templates use `<.form for={@form} id="...">` with `<.input field={@form[:field]} />`
- You are FORBIDDEN from accessing the changeset in the template, and **never** use `<.form let={f} ...>`
<!-- phoenix:liveview-end -->

<!-- usage-rules-end -->
