#!/bin/bash

cd "$(dirname "$0")"

set -e

# Check Node.js version
NODE_REQUIRED=20
NODE_VERSION=""

# Function to check if nvm is available
has_nvm() {
  [ -n "$NVM_DIR" ] && [ -s "$NVM_DIR/nvm.sh" ]
}

# Function to check Node.js version
check_node_version() {
  if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v | cut -d'v' -f2)
    NODE_MAJOR_VERSION=$(echo $NODE_VERSION | cut -d'.' -f1)
    [ "$NODE_MAJOR_VERSION" -ge "$NODE_REQUIRED" ]
    return $?
  fi
  return 1
}

# Check if we already have a suitable Node.js version
if check_node_version; then
  echo "✓ Using Node.js $NODE_VERSION"
else
  # Node.js is either not installed or version is too old
  if has_nvm; then
    echo "⚠️  Node.js $NODE_REQUIRED+ is required (found $NODE_VERSION)."
    echo "🔍 nvm is detected. We can help you switch to Node.js $NODE_REQUIRED."
    
    # Load nvm
    . "$NVM_DIR/nvm.sh"
    
    # Check if Node.js 20 is already installed via nvm
    if nvm ls $NODE_REQUIRED &> /dev/null; then
      echo "✓ Found Node.js $NODE_REQUIRED in nvm"
      nvm use $NODE_REQUIRED
      echo "✓ Switched to Node.js $NODE_REQUIRED"
    else
      echo "🔧 Node.js $NODE_REQUIRED is not installed via nvm. Would you like to install it? (y/n)"
      read -p "→ " INSTALL_NODE
      if [[ $INSTALL_NODE =~ ^[Yy]$ ]]; then
        echo "⏳ Installing Node.js $NODE_REQUIRED via nvm (this may take a few minutes)..."
        nvm install $NODE_REQUIRED
        nvm use $NODE_REQUIRED
        echo "✓ Node.js $NODE_REQUIRED installed and activated"
      else
        echo "❌ Node.js $NODE_REQUIRED+ is required. Please install it manually."
        exit 1
      fi
    fi
  else
    # No nvm, show manual installation instructions
    if [ -z "$NODE_VERSION" ]; then
      echo "❌ Node.js is not installed."
    else
      echo "❌ Node.js version $NODE_VERSION is not supported."
    fi
    echo "Please install Node.js version $NODE_REQUIRED or higher, or install nvm to manage Node.js versions."
    echo "- Download Node.js: https://nodejs.org/"
    echo "- Install nvm: https://github.com/nvm-sh/nvm#installing-and-updating"
    exit 1
  fi
fi

echo "📁 Project name:"
read PROJECT_NAME

# Display package manager selection menu
echo -e "\n📦 Choose your package manager:"

echo "1) npm - Standard Node.js package manager (recommended)"
echo "2) yarn - Fast and reliable package manager"
echo "3) pnpm - Fast, disk space efficient package manager"

while true; do
  read -p "→ Your choice [1-3]: " choice
  
  case $choice in
    1) PACKAGE_MANAGER="npm"; break ;;
    2) PACKAGE_MANAGER="yarn"; break ;;
    3) PACKAGE_MANAGER="pnpm"; break ;;
    *) echo -e "❌ Invalid option. Please try again.\n" ;;
  esac
done

echo -e "\n✅ Selected package manager: $PACKAGE_MANAGER\n"

# Check if package manager is installed, offer to install if not
if ! command -v $PACKAGE_MANAGER &> /dev/null; then
  echo "❌ $PACKAGE_MANAGER is not installed. Would you like to install it? (y/n)"
  read INSTALL_PM
  if [ "$INSTALL_PM" == "y" ]; then
    case $PACKAGE_MANAGER in
      yarn)
        npm install -g yarn
        ;;
      pnpm)
        npm install -g pnpm
        ;;
      *)
        echo "Unknown package manager or cannot be installed automatically."
        exit 1
        ;;
    esac
  else
    echo "Script stopped."
    exit 1
  fi
fi

# Project type selection
echo "🌐 Project type:"
echo "1) HTML/CSS"
echo "2) React"
echo "3) Next.js"
echo "4) Astro"
read -p "Your choice: " PROJECT_TYPE

case $PROJECT_TYPE in
  "1")
    mkdir "$PROJECT_NAME"
    cd "$PROJECT_NAME"
    mkdir src
    echo "<!DOCTYPE html><html><head><title>$PROJECT_NAME</title></head><body><h1>Hello $PROJECT_NAME</h1></body></html>" > src/index.html
    echo "🧱 HTML/CSS project created."
    ;;
  "2")
    npm create vite@latest "$PROJECT_NAME" -- --template react
    cd "$PROJECT_NAME"
    echo "⚛️ React project with Vite created."
    mkdir -p src/components

    echo "Single page or multi-page app? (1) Single (2) Multi-page"
    read REACT_TYPE

    if [ "$REACT_TYPE" == "2" ]; then
      $PACKAGE_MANAGER install react-router-dom
      mkdir -p src/pages src/routes

      cat > src/pages/Home.jsx <<EOF
export default function Home() {
  return <h1>Home</h1>;
}
EOF

      cat > src/pages/Contact.jsx <<EOF
export default function Contact() {
  return <h1>Contact</h1>;
}
EOF

      cat > src/pages/About.jsx <<EOF
export default function About() {
  return <h1>About</h1>;
}
EOF

      cat > src/routes/routes.jsx <<EOF
import { createBrowserRouter } from 'react-router-dom';
import Home from '../pages/Home';
import Contact from '../pages/Contact';
import About from '../pages/About';

const router = createBrowserRouter([
  { path: '/', element: <Home /> },
  { path: '/contact', element: <Contact /> },
  { path: '/about', element: <About /> },
]);

export default router;
EOF
    fi
    ;;
  "3")
    npx create-next-app@latest "$PROJECT_NAME" --typescript --eslint --tailwind --app --src-dir --import-alias "@/*"
    cd "$PROJECT_NAME"
    echo "⚡ Next.js project created with TypeScript, ESLint, Tailwind CSS and app directory."
    ;;
  "4")
    npm create astro@latest "$PROJECT_NAME"
    cd "$PROJECT_NAME"
    echo "🚀 Astro project created."
    ;;
  *)
    echo "❌ Invalid option"
    exit 1
    ;;
esac

# Project description and author
echo "📝 Project description:"
read DESCRIPTION

echo "👤 Author name:"
read AUTHOR

# Create README.md
cat > README.md <<EOF
# $PROJECT_NAME

$DESCRIPTION

## Installation

\`\`\`bash
$PACKAGE_MANAGER install
\`\`\`

## Getting Started

\`\`\`bash
$PACKAGE_MANAGER run dev
\`\`\`
EOF

# Set up ESLint + Prettier
$PACKAGE_MANAGER install -D eslint prettier

echo '{}' > .eslintrc
echo '{}' > .prettierrc
echo 'node_modules' > .eslintignore
echo 'node_modules' > .prettierignore

# Create .gitignore
cat > .gitignore <<EOF
node_modules
dist
.next
.vite
.env
.DS_Store
.env
EOF

# License selection
echo "📄 Choose a license (1) MIT (2) Apache 2.0 (3) GPL v3 (4) None"
read LICENSE_CHOICE

YEAR=$(date +"%Y")

case $LICENSE_CHOICE in
  1)
    cat > LICENSE <<EOF
MIT License

Copyright (c) $YEAR $AUTHOR

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
EOF
    ;;
  2)
    cat > LICENSE <<EOF
Copyright (c) $YEAR $AUTHOR

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
EOF
    ;;
  3)
    cat > LICENSE <<EOF
Copyright (c) $YEAR $AUTHOR

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
EOF
    ;;
  *)
    echo "No license added."
    ;;
esac

# --- Git initialization ------------------------------------------------------
if [ ! -d .git ]; then
  git init
  echo "✅ Git repository initialized"
else
  echo "ℹ️ Git repository already initialized"
fi

# --- Initialize BMAD method --------------------------------------------------
echo -e "\n🤖 Would you like to "BMAD-ify" this project for Claude Code? (y/n)"
read -p "→ " CONFIRM_BMAD

if [[ "$CONFIRM_BMAD" =~ ^[Yy]$ ]]; then
    echo "⏳ Preparing BMAD expert team..."
    # Launch the official installer.
    # The script is already in the right folder thanks to previous 'cd' commands.
    npx bmad-method@alpha install

    echo "✅ BMAD structure (Docs, .bmad) and Claude Code commands ready."
fi
# -----------------------------------------------------------------------------

# Ask to open in editor
echo -e "\n🛠️  Open project in editor?"
echo "1) VS Code"
echo "2) Windsurf"
echo "3) No thanks"

while true; do
  read -p "→ Your choice [1-3]: " editor_choice
  
  case $editor_choice in
    1)
      if command -v code &> /dev/null; then
        code .
        echo "✅ Project opened in VS Code"
      else
        echo "❌ VS Code is not installed or not in PATH"
      fi
      break
      ;;
    2)
      if command -v windsurf &> /dev/null; then
        windsurf .
        echo "✅ Project opened in Windsurf"
      else
        echo "❌ Windsurf is not installed or not in PATH"
      fi
      break
      ;;
    3)
      echo "✅ Alright, you can open it later with:"
      echo "   cd $(pwd)"
      break
      ;;
    *) 
      echo -e "❌ Invalid option. Please try again.\n"
      ;;
  esac
done

echo -e "\n🎉 Project $PROJECT_NAME is ready to code!"
exec bash
