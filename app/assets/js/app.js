// CSS is compiled separately by the Tailwind CLI (see Procfile.dev) — never
// import it here; esbuild only bundles JS in this pipeline.

// Hotwire Turbo — full page drive, frames, and streams
import "@hotwired/turbo";

// Stimulus Application
import { Application } from "@hotwired/stimulus";

// Controllers
import ThemeController from "./controllers/theme_controller";
import DesafioController from "./controllers/desafio_controller";
import SandboxController from "./controllers/sandbox_controller";
import BlitzController from "./controllers/blitz_controller";
import RevealController from "./controllers/reveal_controller";

const application = Application.start();

application.register("theme", ThemeController);
application.register("desafio", DesafioController);
application.register("sandbox", SandboxController);
application.register("blitz", BlitzController);
application.register("reveal", RevealController);
