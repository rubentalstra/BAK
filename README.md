# Bak-Tracker


### **Bottom Navigation Tabs (Navbar)**

#### **If the User Has Joined an Association:**

1. **Home Tab**
   - **Icon:** 🏠 Home
   - **Purpose:** The main dashboard showing stats and leaderboard related to the selected association.
   - **Actions:**
     - View "bakken" stats: total "bakken" given, received, and pending approval.
     - View the **leaderboard** for the current association (Top Givers and Biggest Debt Holders).
     - **Switch between associations** using the dropdown in the AppBar (accessible only if the user is part of multiple associations).
     - Quick links to:
       - **Add a Bak**
       - **View Pending Approvals**
       - **View Transaction History**
     - The **FAB button** for joining an association is **hidden** once the user is part of an association.

2. **Add Bak Tab**
   - **Icon:** ➕ Add Bak
   - **Purpose:** Allow users to send a new "bak" to another member of their current association.
   - **Actions:**
     - Select a member from the association.
     - Enter the number of "bakken" to give.
     - Submit the "bak" request (pending approval from the receiver).

3. **Pending Approvals Tab**
   - **Icon:** ⏳ Pending Approvals
   - **Purpose:** Show a list of pending "bakken" that require the user’s approval or need approval from others.
   - **Actions:**
     - Approve or reject "bakken" requests sent by other members.
     - See pending "bakken" the user has sent, awaiting approval.

4. **History Tab**
   - **Icon:** 📜 History
   - **Purpose:** Provide a full list of "bakken" transactions for the current association.
   - **Actions:**
     - View all completed "bakken" transactions.
     - Filter the transaction history by date or member.
     - Search for specific transactions.

5. **Settings Tab**
   - **Icon:** ⚙️ Settings
   - **Purpose:** Manage association-related settings (for admins) or join a new association.
   - **Actions:**
     - **Join Association**: Enter a code to join a new association via the dropdown in the AppBar.
     - **Association Settings (Admin Only)**: Access admin-specific actions like inviting members, managing roles, and updating association info.

---

#### **If the User Hasn’t Joined an Association Yet:**

1. **Home Tab**
   - **Icon:** 🏠 Home
   - **Purpose:** Encourage the user to join or create an association.
   - **Actions:**
     - Show a **message** indicating the user needs to join or create an association to start using the app.
     - The **FAB button** allows users to **Join an Association** via a code.
     - The **dropdown in the AppBar** allows users to create a new association.
     - **Disable or hide leaderboard, stats, and other association-specific content**.

2. **Add Bak Tab**
   - **Hidden**: The "Add Bak" tab should not be visible since the user is not part of an association.

3. **Pending Approvals Tab**
   - **Hidden**: This tab should not be visible since there are no pending "bakken" without an association.

4. **History Tab**
   - **Hidden**: Since no "bakken" transactions exist without an association, this tab should also be hidden.

5. **Settings Tab**
   - **Visible**: Users can still access the **Join Association** option, but no association-specific settings (such as Association Settings for admins) will be shown.

---

### **Screens Overview**

#### **If the User Has Joined an Association:**

1. **Splash Screen**
   - **Purpose:** Display the app logo or animation while checking if the user is authenticated.
   - **Actions:**
     - If logged in, navigate to the **Home Screen**.
     - If not logged in, navigate to the **Login Screen**.

2. **Login Screen**
   - **Purpose:** Allow users to log in with their Google account.
   - **Actions:**
     - Google Sign-In button.
     - Redirect to the **Home Screen** after successful login.

3. **Home Screen**
   - **Purpose:** Display user stats, leaderboard, and allow users to switch between associations.
   - **Actions:**
     - **Switch associations** using a dropdown (if applicable) in the AppBar.
     - View personal "bakken" stats.
     - View the **Leaderboard**: Top Givers and Biggest Debt Holders.
     - Quick links to Add a Bak, Pending Approvals, and History.

4. **Association Selection Screen**
   - **Purpose:** Allow users to select between multiple associations (if applicable).
   - **Actions:**
     - List all associations the user is part of.
     - Select an association to switch the context of the app.

5. **Add Bak Screen**
   - **Purpose:** Allow the user to give a "bak" to another member of their association.
   - **Actions:**
     - Select a member.
     - Enter the number of "bakken."
     - Submit the request.

6. **Pending Approvals Screen**
   - **Purpose:** Manage pending "bakken" requests that require the user’s approval.
   - **Actions:**
     - Approve or reject pending "bakken."
     - View pending "bakken" the user has sent to others.

7. **History Screen**
   - **Purpose:** Show a detailed history of all "bakken" transactions.
   - **Actions:**
     - View completed "bakken."
     - Filter and search transaction history.

8. **Join Association Screen (Settings)**
   - **Purpose:** Allow users to enter a code to join a new association.
   - **Actions:**
     - Enter and submit an association code.
     - If valid, join the association and update the app’s context.

9. **Association Settings Screen (Admin Only)**
    - **Purpose:** Allow admins to manage the association.
    - **Actions:**
      - **Invite Members**: Send invites to new members.
      - **Manage Roles**: Assign or change user roles within the association.
      - **Remove Members**: Remove or block members from the association.
      - **Edit Association Info**: Change association name and other metadata.

---

#### **If the User Hasn’t Joined an Association Yet:**

1. **Splash Screen**
   - **Same as when the user has joined an association**.

2. **Login Screen**
   - **Same as when the user has joined an association**.

3. **Home Screen**
   - **Purpose:** Encourage the user to join or create an association.
   - **Actions:**
     - **FAB Button**: Allows the user to **Join an Association** using a code.
     - **Dropdown in the AppBar**: Allows the user to create a new association.

4. **Add Bak Screen**
   - **Hidden**: The user can’t give a "bak" without being part of an association.

5. **Pending Approvals Screen**
   - **Hidden**: No pending approvals without an association.

6. **History Screen**
   - **Hidden**: No history to display without an association.

7. **Join Association Screen (Settings)**
   - **Same as when the user has joined an association**.

8. **Association Settings Screen (Admin Only)**
   - **Hidden**: Not applicable since the user is not part of any associations.

---

### Flow and Behavior Adjustments
- **If the User Has Joined an Association:** The full app functionality is available, and the user can switch associations via the dropdown in the AppBar. The FAB button is hidden.
- **If the User Hasn’t Joined an Association:** The FAB button is visible to join an association, while the app bar dropdown allows the user to create a new association. Non-relevant screens (e.g., Add Bak, History) are hidden.

