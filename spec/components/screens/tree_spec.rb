# frozen_string_literal: true

RSpec.describe RegexDojo::Components::Screens::Tree, type: :component do
  def belt_road_pill_texts(fragment)
    fragment.css("div.overflow-x-auto span.rounded-full").map { |el| el.text.strip }
  end

  it "marks belts before the current one as done, the current one as active, and the rest as locked" do
    user = build_user_presenter(belt: "orange")
    tree = described_class.new(user: user, solved_kata_ids: [], katas: [])

    pills = belt_road_pill_texts(render_fragment(tree))

    expect(pills).to eq(["✓ Done", "✓ Done", "▶ Now", "Locked", "Locked"])
  end

  it "treats an unrecognized belt as the first (white) belt" do
    user = build_user_presenter(belt: "not-a-real-belt")
    tree = described_class.new(user: user, solved_kata_ids: [], katas: [])

    pills = belt_road_pill_texts(render_fragment(tree))

    expect(pills).to eq(["▶ Now", "Locked", "Locked", "Locked", "Locked"])
  end

  it "disables kata buttons in locked belt groups" do
    user = build_user_presenter(belt: "white")
    katas = (0..3).map { |i| build_kata(id: i.to_s, title: "Kata #{i}") }
    tree = described_class.new(user: user, solved_kata_ids: [], katas: katas)

    fragment = render_fragment(tree)
    buttons = fragment.css('[data-dojo-target="kataButton"]')

    # index_range 0..2 is the white belt group (unlocked when belt is white);
    # kata 3 falls into the yellow group (index_range 3..5), which is locked.
    expect(buttons[0]["disabled"]).to be_nil
    expect(buttons[3]["disabled"]).not_to be_nil
  end

  it "marks a solved kata with the solved indicator instead of play/locked" do
    user = build_user_presenter(belt: "white")
    katas = [build_kata(id: "1", title: "Solved kata")]
    tree = described_class.new(user: user, solved_kata_ids: ["1"], katas: katas)

    fragment = render_fragment(tree)
    button = fragment.at_css('[data-dojo-target="kataButton"]')

    expect(button.text).to include("✓ Solved")
    expect(button["data-kata-solved"]).to eq("true")
  end

  it "carries kata data through to the button's data attributes for the JS controller" do
    user = build_user_presenter(belt: "white")
    katas = [build_kata(id: "42", title: "Digit match", xp: 25)]
    tree = described_class.new(user: user, solved_kata_ids: [], katas: katas)

    fragment = render_fragment(tree)
    button = fragment.at_css('[data-dojo-target="kataButton"]')

    expect(button["data-kata-id"]).to eq("42")
    expect(button["data-kata-title"]).to eq("Digit match")
    expect(button["data-kata-xp"]).to eq("25")
  end

  it "shows the solved-kata count against the total" do
    user = build_user_presenter(belt: "white")
    katas = [build_kata(id: "1"), build_kata(id: "2")]
    tree = described_class.new(user: user, solved_kata_ids: ["1"], katas: katas)

    fragment = render_fragment(tree)

    expect(fragment.text).to include("1/2 Katas Solved")
  end
end
