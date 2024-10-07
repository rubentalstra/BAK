package com.baktracker

import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition

import android.content.Context
import android.content.res.Configuration
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import android.content.Intent
import androidx.compose.ui.unit.DpSize
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import androidx.glance.appwidget.SizeMode

class BAKGlanceWidget : GlanceAppWidget() {

    // Define the colors for both light and dark mode
    private val lightSecondary = Color(red = 218, green = 164, blue = 66, alpha = 255)
    private val captionColor = Color(red = 176, green = 190, blue = 197, alpha = 255)

    private val lightBackgroundColor = Color(red = 61, green = 74, blue = 81, alpha = 255)
    private val darkBackgroundColor = Color(red = 29, green = 40, blue = 45, alpha = 255)

    // Define widget sizes to respond to different screen sizes
    companion object {
        private val TWO_BY_ONE = DpSize(110.dp, 40.dp)  // Corresponding to 2x1 widget size
        private val FOUR_BY_ONE = DpSize(250.dp, 40.dp) // Corresponding to 4x1 widget size
    }

    // Use SizeMode.Responsive to handle multiple sizes
    override val sizeMode = SizeMode.Responsive(
        setOf(TWO_BY_ONE, FOUR_BY_ONE)
    )

    override val stateDefinition: GlanceStateDefinition<*>
        get() = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceContent(currentState(), context)
        }
    }

    @Composable
    private fun GlanceContent(currentState: HomeWidgetGlanceState, context: Context) {
        val prefs = currentState.preferences
        val associationName = prefs.getString("association_name", "Association") ?: "Association"
        val chuckedDrinks = prefs.getString("chucked_drinks", "0") ?: "0"
        val drinkDebt = prefs.getString("drink_debt", "0") ?: "0"
        val betsWon = prefs.getString("bets_won", "0") ?: "0"
        val betsLost = prefs.getString("bets_lost", "0") ?: "0"

        // Determine background color based on system theme
        val backgroundColor = if (isDarkMode(context)) {
            ColorProvider(darkBackgroundColor) // Dark mode background
        } else {
            ColorProvider(lightBackgroundColor) // Light mode background
        }

        // Create an intent to open the Flutter app when clicked
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }

        val size = LocalSize.current

        Column(
            modifier = GlanceModifier
                .fillMaxSize() // Fill the entire widget size
                .background(backgroundColor)
                .padding(8.dp)
                .clickable(actionStartActivity(intent)), // Make the widget clickable
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Association Name (always visible)
            Text(
                text = associationName,
                style = TextStyle(
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = ColorProvider(lightSecondary)
                ),
                modifier = GlanceModifier.padding(bottom = 8.dp)
            )

            // Conditionally show content based on widget size
            if (size.width <= TWO_BY_ONE.width && size.height <= TWO_BY_ONE.height) {
                // For 2x1 widget size, only show BAK and Chucked Drinks
                Row(
                    modifier = GlanceModifier.fillMaxSize(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // BAK
                    Column(
                        modifier = GlanceModifier.padding(end = 24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "BAK",
                            style = TextStyle(
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                color = ColorProvider(captionColor)
                            ),
                            modifier = GlanceModifier.padding(bottom = 4.dp)
                        )
                        Text(
                            text = drinkDebt,
                            style = TextStyle(
                                fontSize = 28.sp,
                                color = ColorProvider(Color.Red)
                            )
                        )
                    }

                    // Chucked Drinks
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "Chucked",
                            style = TextStyle(
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                color = ColorProvider(captionColor)
                            ),
                            modifier = GlanceModifier.padding(bottom = 4.dp)
                        )
                        Text(
                            text = chuckedDrinks,
                            style = TextStyle(
                                fontSize = 28.sp,
                                color = ColorProvider(Color.Green)
                            )
                        )
                    }
                }
            } else if (size.width >= FOUR_BY_ONE.width) {
                // For 4x1 widget size, show all four items
                Row(
                    modifier = GlanceModifier.fillMaxSize(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // BAK
                    Column(
                        modifier = GlanceModifier.padding(end = 24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "BAK",
                            style = TextStyle(
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                color = ColorProvider(captionColor)
                            ),
                            modifier = GlanceModifier.padding(bottom = 4.dp)
                        )
                        Text(
                            text = drinkDebt,
                            style = TextStyle(
                                fontSize = 28.sp,
                                color = ColorProvider(Color.Red)
                            )
                        )
                    }

                    // Chucked Drinks
                    Column(
                        modifier = GlanceModifier.padding(end = 24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "Chucked",
                            style = TextStyle(
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                color = ColorProvider(captionColor)
                            ),
                            modifier = GlanceModifier.padding(bottom = 4.dp)
                        )
                        Text(
                            text = chuckedDrinks,
                            style = TextStyle(
                                fontSize = 28.sp,
                                color = ColorProvider(Color.Green)
                            )
                        )
                    }

                    // Bets Won
                    Column(
                        modifier = GlanceModifier.padding(end = 24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "Bets Won",
                            style = TextStyle(
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                color = ColorProvider(captionColor)
                            ),
                            modifier = GlanceModifier.padding(bottom = 4.dp)
                        )
                        Text(
                            text = betsWon,
                            style = TextStyle(
                                fontSize = 28.sp,
                                color = ColorProvider(Color.Blue)
                            )
                        )
                    }

                    // Bets Lost
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "Bets Lost",
                            style = TextStyle(
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                color = ColorProvider(captionColor)
                            ),
                            modifier = GlanceModifier.padding(bottom = 4.dp)
                        )
                        Text(
                            text = betsLost,
                            style = TextStyle(
                                fontSize = 28.sp,
                                color = ColorProvider(Color.Red)
                            )
                        )
                    }
                }
            }
        }
    }

    // Function to determine if the system is in dark mode
    private fun isDarkMode(context: Context): Boolean {
        val nightModeFlags = context.resources.configuration.uiMode and
                Configuration.UI_MODE_NIGHT_MASK
        return nightModeFlags == Configuration.UI_MODE_NIGHT_YES
    }
}