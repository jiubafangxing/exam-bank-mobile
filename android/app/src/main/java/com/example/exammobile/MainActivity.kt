package com.example.exammobile

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import androidx.navigation.compose.rememberNavController
import com.example.exammobile.ui.navigation.AppNavHost
import com.example.exammobile.ui.navigation.Routes
import com.example.exammobile.ui.theme.ExamMobileTheme
import com.example.exammobile.ui.util.toast
import com.example.exammobile.ui.viewmodel.AuthEvent
import com.example.exammobile.ui.viewmodel.AuthViewModel

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val container = (application as ExamMobileApp).container

        setContent {
            ExamMobileTheme {
                val navController = rememberNavController()
                val context = LocalContext.current
                val authVm: AuthViewModel = viewModel(
                    factory = viewModelFactory {
                        initializer { AuthViewModel(container.repository, container.sessionStore) }
                    }
                )

                LaunchedEffect(Unit) { authVm.loadMeta() }

                LaunchedEffect(Unit) {
                    authVm.uiEvents.collect { event ->
                        when (event) {
                            is AuthEvent.Toast -> context.toast(event.message)
                            AuthEvent.NeedTenant -> navController.navigate(Routes.TENANT)
                            AuthEvent.LoggedIn -> navController.navigate(Routes.HOME) {
                                popUpTo(0) { inclusive = true }
                                launchSingleTop = true
                            }
                            AuthEvent.LoggedOut -> navController.navigate(Routes.LOGIN) {
                                popUpTo(0) { inclusive = true }
                                launchSingleTop = true
                            }
                            AuthEvent.PasswordReset -> navController.navigate(Routes.LOGIN) {
                                popUpTo(Routes.RESET_PASSWORD) { inclusive = true }
                            }
                        }
                    }
                }

                LaunchedEffect(Unit) {
                    container.unauthorizedEvents.collect {
                        context.toast("登录已过期，请重新登录")
                        navController.navigate(Routes.LOGIN) {
                            popUpTo(0) { inclusive = true }
                            launchSingleTop = true
                        }
                    }
                }

                AppNavHost(
                    container = container,
                    authVm = authVm,
                    startLoggedIn = container.sessionStore.token != null,
                    navController = navController
                )
            }
        }
    }
}
