if !has('patch-8.0.0')
	finish
endif

let g:asynctasks_template = {}

let g:asynctasks_template.cmake = [
			\ "[project-init]",
			\ "command=mkdir build && cd build && cmake ..",
			\ "cwd=<root>",
			\ "",
			\ "[project-build]",
			\ "command=cmake --build build",
			\ "cwd=<root>",
			\ "errorformat=%. %#--> %f:%l:%c",
			\ "",
			\ "[project-run]",
			\ "command=build/$(VIM_PRONAME)",
			\ "cwd=<root>",
			\ "output=terminal",
			\ ]

let g:asynctasks_template.cargo = [
			\ "[project-init]",
			\ "command=cargo update",
			\ "cwd=<root>",
			\ "",
			\ "[project-build]",
			\ "command=cargo build",
			\ "cwd=<root>",
			\ "",
			\ "[project-run]",
			\ "command=cargo run",
			\ "cwd=<root>",
			\ "output=terminal",
			\ ]


