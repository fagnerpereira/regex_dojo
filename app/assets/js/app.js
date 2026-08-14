// CSS is compiled separately by the Tailwind CLI (see Procfile.dev) — never
// import it here; esbuild only bundles JS in this pipeline.

// Hotwire Turbo — full page drive, frames, and streams
import "@hotwired/turbo";

// Stimulus Application
import { Application } from "@hotwired/stimulus";

// Controllers
import TabsController from "./controllers/tabs_controller";
import DojoController from "./controllers/dojo_controller";
import SandboxController from "./controllers/sandbox_controller";
import BlitzController from "./controllers/blitz_controller";
import RubyDojoController from "./controllers/ruby_dojo_controller";
import ThemeController from "./controllers/theme_controller";
import DesafioController from "./controllers/desafio_controller";

const application = Application.start();

application.register("tabs", TabsController);
application.register("dojo", DojoController);
application.register("sandbox", SandboxController);
application.register("blitz", BlitzController);
application.register("ruby-dojo", RubyDojoController);
application.register("theme", ThemeController);
application.register("desafio", DesafioController);
