defmodule SanehRoiRosWeb.CategoryTabs do
  @moduledoc """
  Menu category tabs used on every ordering page (app-specific: the fixed
  category list lives here, not in the generic `SanehRoiRosUI` kit).
  """
  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  @categories ~w(ก๋วยเตี๋ยว ข้าว กับข้าว เพิ่มเติม เครื่องดื่ม ไอศกรีม ขนมถุง)

  @doc """
  Category tabs — one component for every ordering page, fixed order of 7:
  #{Enum.join(@categories, " · ")}.

  Normally the tabs wrap onto two rows. Once the page is scrolled down past
  ~40px the `.CategoryTabs` hook switches them to a compact sticky single
  row (swipeable, no scrollbar, active tab kept in view). Back at the top they
  expand again. The compact state survives LiveView patches.

  `position: sticky` only works inside its parent box, so render the tabs as
  a direct child of the page column (e.g. in `<UI.screen>`'s `:top` slot), not
  inside a wrapper that is only as tall as the tabs.

      <.category_tabs id="tabs" active={@category} on_select="category" />
  """
  attr :id, :string, required: true
  attr :active, :string, default: nil
  attr :categories, :list, default: @categories
  attr :on_select, :any, default: nil, doc: "event name or `%JS{}`; gets `phx-value-category`"
  attr :target, :any, default: nil
  attr :threshold, :integer, default: 40, doc: "scroll offset (px) that enables compact mode"
  attr :class, :any, default: nil
  attr :rest, :global

  def category_tabs(assigns) do
    ~H"""
    <nav
      id={@id}
      aria-label="หมวดเมนู"
      phx-hook=".CategoryTabs"
      data-threshold={@threshold}
      class={[
        "category-tabs relative z-10 flex flex-wrap gap-1.5 border-b border-line-soft bg-bg px-4 pt-0.5 pb-3",
        "data-compact:sticky data-compact:top-0 data-compact:flex-nowrap data-compact:overflow-x-auto",
        "data-compact:pt-2 data-compact:shadow-header",
        @class
      ]}
      {@rest}
    >
      <button
        :for={{category, index} <- Enum.with_index(@categories)}
        id={"#{@id}-#{index}"}
        type="button"
        aria-pressed={to_string(category == @active)}
        phx-click={@on_select}
        phx-value-category={category}
        phx-target={@target}
        class={[
          "h-[38px] flex-none cursor-pointer rounded-full border-[1.5px] px-3.5 text-[15px] whitespace-nowrap",
          "transition-colors duration-150",
          if(category == @active,
            do: "border-primary bg-primary font-bold text-white",
            else: "border-line bg-surface font-medium text-primary hover:bg-white"
          )
        ]}
      >
        {category}
      </button>
    </nav>
    <script :type={ColocatedHook} name=".CategoryTabs">
      export default {
        mounted() {
          this.compact = false
          this.threshold = parseInt(this.el.dataset.threshold || "40", 10)
          this.onScroll = () => {
            const y = window.scrollY
            if (!this.compact && y > this.threshold) this.setCompact(true)
            else if (this.compact && y <= 4) this.setCompact(false)
          }
          window.addEventListener("scroll", this.onScroll, {passive: true})
          this.onScroll()
        },
        updated() {
          if (this.compact) this.revealActive()
        },
        destroyed() {
          window.removeEventListener("scroll", this.onScroll)
        },
        setCompact(on) {
          this.compact = on
          if (on) {
            this.js().setAttribute(this.el, "data-compact", "")
            requestAnimationFrame(() => this.revealActive())
          } else {
            this.js().removeAttribute(this.el, "data-compact")
            this.el.scrollLeft = 0
          }
        },
        revealActive() {
          const tab = this.el.querySelector('[aria-pressed="true"]')
          if (!tab) return
          const left = tab.offsetLeft - (this.el.clientWidth - tab.offsetWidth) / 2
          this.el.scrollTo({left: Math.max(0, left), behavior: "smooth"})
        }
      }
    </script>
    """
  end

  @doc "The fixed list of menu categories, in display order."
  def categories, do: @categories
end
