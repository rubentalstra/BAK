# BAK

BAK is a mobile app designed for student associations to manage and track
"bakken" – a Dutch term referring to drink debts within associations. The app
allows members to send, track, and approve bakken, manage association
memberships, and engage with other members through bets and competitions. The
app is invite-only, ensuring privacy and exclusivity for each association.

## Features

- **Invite-Only Membership**: Join associations by invitation only, using unique
  invite codes.
- **Multiple Associations**: Manage memberships across multiple associations and
  easily switch between them.
- **Role-Based Permissions**: Assign and manage roles such as "Voorzitter,"
  "Penningmeester," and more, with custom permissions for each user.
- **Bak Tracking**: Send and receive "bakken," track pending approvals, and
  manage your bak history.
- **Leaderboards**: Stay competitive with leaderboard rankings for both bak
  debts and bak consumption.
- **Bets**: Create and track bets with other members. Losers get assigned
  additional bakken based on the outcome of the bet.
- **Association Requests**: Submit requests to create an association and get
  approved by providing your association's website.
- **Profile Management**: Update your profile information, including display
  name and profile picture.
- **Deep Linking**: Automatically join an association by clicking an invite link
  shared by other members.

## Screens

1. **Home Screen**: Displays your association's leaderboard and allows you to
   switch between associations.
2. **Add Bak**: Send a bak to another member in your association.
3. **Pending Approvals**: View and manage pending bak requests that need
   approval.
4. **History**: View a full list of all bak transactions you've been involved
   in.
5. **Settings**: Manage your profile, join new associations, and adjust app
   preferences.

## Getting Started

### Prerequisites

- Flutter SDK
- Supabase account (for authentication and database)
- Dart >= 2.12.0

### Installation

1. Clone the repository:

```bash
git clone https://github.com/rubentalstra/BAK.git
```

2. Install dependencies:

```bash
flutter pub get
```

3. Configure Supabase:

- Set Up Environment Variables:
  - Create a `.env` file in the root of your project with the following
    structure:

    ```env
    # Supabase-related environment variables
    SUPABASE_URL=https://your-supabase-url.supabase.co
    SUPABASE_ANON_KEY=your-supabase-anon-key

    # Google OAuth Client IDs
    YOUR_WEB_CLIENT_ID=your-google-oauth-web-client-id
    YOUR_IOS_CLIENT_ID=your-google-oauth-ios-client-id
    ```

  - Ensure you replace the placeholder values with your actual Supabase URL, API
    key, and Google OAuth client IDs.

- These environment variables are automatically generated into `env.g.dart` via
  the `envied` package. Make sure you have this file properly set up to access
  the environment variables in your code.

4. Run the app:

```bash
flutter run
```

### Usage

- Create or join an association using an invite code.
- Assign roles to members and manage permissions.
- Track, send, and approve “bakken.”
- Participate in bets and keep track of winners and losers.
- View leaderboard rankings for all members in your association.

## Project Structure

- `lib/`: Contains the main Flutter codebase and entry point of the application.
- `lib/models/`: Contains the data models for associations, members, bak
  transactions, bets, permissions, and more. These models manage the structure
  of the app's data and include methods to convert to and from maps for database
  interactions.
- `lib/screens/`: Includes all the UI screens such as Home, Add Bak, Pending
  Approvals, History, and Settings. Each screen provides a user-friendly
  interface to interact with the app's functionality.
- `lib/services/`: Handles authentication, database access, and API requests.
  These services connect the app with Supabase for managing associations, user
  data, and transactions.
- `lib/bloc/`: Manages state using the Bloc pattern. It is responsible for
  handling complex state management across the app, such as user sessions,
  association data, and bak transactions.
- `lib/widgets/`: Contains reusable UI components such as buttons, modals, and
  custom widgets used throughout the app to maintain consistency.
- `lib/constants/`: Stores global constants such as API keys, Supabase URLs, and
  any fixed values used across the app.

## Contributing

We welcome contributions to the BAK Tracker project. To contribute:

1. Fork the repository.
2. Create a new branch:

```bash
git checkout -b feature/your-feature
```

3. Make your changes and commit them

```bash
git commit -am 'Add new feature'
```

4. Push your branch

```bash
git push origin feature/your-feature
```

5. Create a pull request.

Please ensure your code follows our [Code of Conduct](CODE_OF_CONDUCT).

## License

This project is licensed under the GNU General Public License v3.0. See the
[LICENSE](LICENSE) file for details.

```
This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <https://www.gnu.org/licenses/>.
```

## Contact

If you have any questions, issues, or suggestions, please open an issue on the
GitHub repository or reach out via [@rubentalstra](https://github.com/rubentalstra).

Happy Drinking!
