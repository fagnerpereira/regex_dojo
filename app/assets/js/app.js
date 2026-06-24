// CSS is compiled separately by the Tailwind CLI (see Procfile.dev `css`
// process) → public/assets/app.css, linked directly in the layout.
// Do NOT import it here: esbuild can't resolve Tailwind v4's `@import "tailwindcss"`.

// Hotwire Turbo — full page drive, frames, and streams
import "@hotwired/turbo";

// Stimulus Application
import { Application } from "@hotwired/stimulus";

// Controllers
import TabsController from "./controllers/tabs_controller";
import DojoController from "./controllers/dojo_controller";
import SandboxController from "./controllers/sandbox_controller";
import BlitzController from "./controllers/blitz_controller";

const application = Application.start();

application.register("tabs", TabsController);
application.register("dojo", DojoController);
application.register("sandbox", SandboxController);
application.register("blitz", BlitzController);
