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
import androidx.glance.appwidget.GlanceAppWidget
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

class BAKGlanceWidget : GlanceAppWidget() {

    // Define the colors for both light and dark mode
    private val lightSecondary = Color(red = 218, green = 164, blue = 66, alpha = 255)
    private val captionColor = Color(red = 176, green = 190, blue = 197, alpha = 255)

    private val lightBackgroundColor = Color(red = 61, green = 74, blue = 81, alpha = 255)
    private val darkBackgroundColor = Color(red = 29, green = 40, blue = 45, alpha = 255)


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

        // Determine background color based on system theme
        val backgroundColor = if (isDarkMode(context)) {
            ColorProvider(darkBackgroundColor) // Dark mode background
        } else {
            ColorProvider(lightBackgroundColor) // Light mode background
        }

        Column(
            modifier = GlanceModifier
                .fillMaxSize() // Fill the entire widget size
                .background(backgroundColor)
                .padding(8.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Association Name
            Text(
                text = associationName,
                style = TextStyle(
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = ColorProvider(lightSecondary)
                ),
                modifier = GlanceModifier.padding(bottom = 8.dp)
            )

            // Row for BAK and Chucked Drinks
            Row(
                modifier = GlanceModifier.fillMaxSize(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(
                    modifier = GlanceModifier.padding(end = 24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    // BAK
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
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    // Chucked Drinks
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
        }
    }

    // Function to determine if the system is in dark mode
    private fun isDarkMode(context: Context): Boolean {
        val nightModeFlags = context.resources.configuration.uiMode and
                Configuration.UI_MODE_NIGHT_MASK
        return nightModeFlags == Configuration.UI_MODE_NIGHT_YES
    }

}