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
    private val darkRed = Color(red = 255, green = 99, blue = 71, alpha = 255)
    private val lightRed = Color(red = 139, green = 0, blue = 0, alpha = 255)
    private val darkGreen = Color(red = 144, green = 238, blue = 144, alpha = 255)
    private val lightGreen = Color(red = 0, green = 100, blue = 0, alpha = 255)

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
            ColorProvider(Color.Black) // Dark mode background
        } else {
            ColorProvider(Color.White) // Light mode background
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
                            color = ColorProvider(getPrimaryColor(context))
                        ),
                        modifier = GlanceModifier.padding(bottom = 4.dp)
                    )
                    Text(
                        text = drinkDebt,
                        style = TextStyle(
                            fontSize = 28.sp,
                            color = ColorProvider(getRedColor(context))
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
                            color = ColorProvider(getPrimaryColor(context))
                        ),
                        modifier = GlanceModifier.padding(bottom = 4.dp)
                    )
                    Text(
                        text = chuckedDrinks,
                        style = TextStyle(
                            fontSize = 28.sp,
                            color = ColorProvider(getGreenColor(context))
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

    // Function to get primary color based on dark/light mode
    private fun getPrimaryColor(context: Context): Color {
        return if (isDarkMode(context)) {
            Color.White // Dark mode primary text color
        } else {
            Color.Black // Light mode primary text color
        }
    }

    // Function to get red color based on dark/light mode
    private fun getRedColor(context: Context): Color {
        return if (isDarkMode(context)) {
            lightRed // Light red in dark mode for better contrast
        } else {
            darkRed // Dark red in light mode
        }
    }

    // Function to get green color based on dark/light mode
    private fun getGreenColor(context: Context): Color {
        return if (isDarkMode(context)) {
            lightGreen // Light green in dark mode
        } else {
            darkGreen // Dark green in light mode
        }
    }
}