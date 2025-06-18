# Introduction

CrimeToGo is a multiplayer online detective game where players collaborate to solve crimes. The game emphasizes teamwork, deduction, and communication as players gather clues, analyze evidence, and work together to identify the culprit.

## Technology Stack

- **Phoenix Framework 1.8** - Real-time web framework
- **Elixir** - Functional programming language
- **mise** - Version management for Elixir, Erlang, and Node.js

# Web Interface & User Experience

## Root Page (Home)

The root page (`/`) is implemented as a **Phoenix LiveView** page, consistent with all pages in the application. This page serves as the main entry point and provides users with two primary actions:

### Game Description
The page prominently displays information about CrimeToGo as a multiplayer crime-solving game, emphasizing the collaborative detective experience where players work together to solve mysteries.

### Game Actions

**Create New Game:**
- Players can initiate a new game session
- Generates a unique game code (12 random digits but without 0, 1 and 7) for sharing with other players
- Sets up the game in `pre_game` state, ready for player registration

**Join Existing Game:**
- Players can join an existing game by entering a valid game code
- Validates the game code against active games
- Redirects to the game lobby upon successful validation

The interface is designed with a clean, intuitive layout that clearly separates these two primary actions while maintaining the application's responsive design principles.

## Design & Styling

The interface uses **Tailwind CSS** exclusively, ensuring a lightweight, consistent design system that's easy to maintain and optimize.

### Dark Mode Support

The application automatically adapts to the user's system preference (`prefers-color-scheme`) for dark or light mode. No manual toggle is provided to maintain consistency with the user's overall system experience.

### Mobile-First Responsive Design

All components and layouts are designed mobile-first, then progressively enhanced for tablets and desktop screens. This ensures optimal performance and usability across all devices.

## Internationalization

CrimeToGo supports multiple languages with automatic browser language detection:

- **German** (default)
- **English**
- **French** 
- **Spanish**
- **Turkish**
- **Russian**
- **Ukrainian**

The application starts with the browser's preferred language, falling back to English if the language isn't supported. Users can switch languages through a clean interface selector.

## Interactive Features

### Phoenix LiveView

**Phoenix LiveView** powers most interactive features, providing real-time updates without the complexity of a separate frontend framework:

- Real-time game state updates
- Live chat and communication
- Dynamic game board updates
- Interactive clue gathering and evidence analysis

### Alpine.js

**Alpine.js** handles client-side interactions when needed:

- Dropdown menus and modal dialogs
- Form input enhancements
- Simple animations and transitions

This combination ensures fast, responsive interactions while maintaining LiveView's simplicity for complex real-time features.

## Navigation & Notifications

### Navigation Bar

The application features a fixed navigation bar at the top of every page that provides consistent access to key features:

- **Game Logo/Brand** - Links to the home page
- **Language Selector** - Dropdown for switching between supported languages
- **Notification Bell** - Real-time notification indicator for new messages
- **User Menu** - Player profile and game management options

### Notification System

#### Bell Icon Indicator

The notification bell icon in the navigation bar provides real-time visual feedback:

- **Inactive State** - Bell icon appears in muted color
- **Active State** - Bell icon pulses with animation and changes color when new messages arrive
- **Click Action** - Opens notification panel or scrolls to latest messages

#### Flash Message System

A fixed flash message area displays important notifications and updates:

- **Position** - Fixed at the top of the main content area, below the navigation bar
- **Types** - Success, error, warning, and info messages
- **Auto-dismiss** - Messages automatically fade out after a configurable duration
- **Manual dismiss** - Users can manually close messages with an X button
- **Real-time updates** - New messages appear instantly via LiveView updates

**Flash Message Triggers:**
- New chat messages in rooms where the player is a member
- Game state changes (game start, end, player joins/leaves)
- System notifications and alerts
- Error messages and validation feedback

**Styling:**
- Uses Tailwind CSS classes for consistent theming
- Adapts to dark/light mode automatically
- Responsive design for mobile and desktop
- Smooth animations for appearance and dismissal

# Game Management

## Game Resource

**Attributes:**
- `id` (UUID)
- `invitation_code` (string, max 20 characters, required)
- `start_at` (timestamp)
- `end_at` (timestamp)
- `state` (enum: `pre_game`, `active`, `post_game`)
- `game_code` (string, max 20 characters, required, unique)

**Relationships:**
- Has many players

**RESTful Routes:**
- `GET /games` (index)
- `GET /games/new` (new)
- `POST /games` (create)
- `GET /games/:id` (show)
- `PATCH/PUT /games/:id` (update)

# Player Management

Players can join games using invitation codes without requiring user accounts.

## Player Resource

**Attributes:**
- `id` (UUID)
- `game_id` (string, belongs to game)
- `game_host` (boolean, defaults to false)
- `is_robot` (boolean, defaults to false)
- `nickname` (string, max 140 characters, required, unique per game)
- `avatar_file_name` (string, max 255 characters, required, unique per game)

**RESTful Routes:**
- `GET /games/:game_id/players` (index)
- `GET /games/:game_id/players/new` (new)
- `POST /games/:game_id/players` (create)
- `GET /games/:game_id/players/:id` (show)
- `PATCH/PUT /games/:game_id/players/:id` (update)

# Chat System

The chat system enables real-time communication between players during the game. It consists of public game chat and private chat rooms for strategic discussions.

## Chat Room Resource

**Attributes:**
- `id` (UUID)
- `game_id` (UUID, belongs to game)
- `name` (string, max 100 characters, required)
- `room_type` (enum: `public`, `private`)
- `created_by` (UUID, belongs to player)

**Relationships:**
- Belongs to game
- Has many chat messages
- Has many chat room members (for private rooms)

**RESTful Routes:**
- `GET /games/:game_id/chat_rooms` (index)
- `POST /games/:game_id/chat_rooms` (create - for private rooms)
- `GET /games/:game_id/chat_rooms/:id` (show)

## Chat Message Resource

**Note:** Messages support soft deletion - they are marked as deleted with a timestamp but remain in the database for audit purposes and can be restored if needed.

**Attributes:**
- `id` (UUID)
- `chat_room_id` (UUID, belongs to chat room)
- `player_id` (UUID, belongs to player)
- `content` (text, max 1000 characters, required)
- `deleted_at` (timestamp, nullable)
- `inserted_at` (timestamp)

**Relationships:**
- Belongs to chat room
- Belongs to player

**RESTful Routes:**
- `GET /games/:game_id/chat_rooms/:chat_room_id/messages` (index)
- `POST /games/:game_id/chat_rooms/:chat_room_id/messages` (create)
- `DELETE /games/:game_id/chat_rooms/:chat_room_id/messages/:id` (soft delete)

## Chat Room Member Resource

**Attributes:**
- `id` (UUID)
- `chat_room_id` (UUID, belongs to chat room)
- `player_id` (UUID, belongs to player)
- `joined_at` (timestamp)

**Relationships:**
- Belongs to chat room
- Belongs to player

**RESTful Routes:**
- `GET /games/:game_id/chat_rooms/:chat_room_id/members` (index)
- `POST /games/:game_id/chat_rooms/:chat_room_id/members` (create)

# Real-time Communication (PubSub)

## PubSub Channels

The application uses Phoenix PubSub for real-time updates across the chat system and game state:

### Game Channels
- `"game:#{game_id}"` - General game updates (state changes, player joins/leaves)
- `"game:#{game_id}:chat"` - Public chat messages for the game

### Chat Room Channels
- `"chat_room:#{chat_room_id}"` - Private chat room messages
- `"chat_room:#{chat_room_id}:members"` - Member join/leave notifications

### Player Channels
- `"player:#{player_id}"` - Personal notifications and invitations

## Message Broadcasting

**Chat Messages:**


