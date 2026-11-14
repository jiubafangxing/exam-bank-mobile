package com.example.exammobile

import android.app.Application
import com.example.exammobile.di.AppContainer

class ExamMobileApp : Application() {

    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = AppContainer(this)
    }
}
