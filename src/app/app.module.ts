import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { AppComponent } from './app.component';
import { FontAwesomeModule } from '@fortawesome/angular-fontawesome';

// Rutas
import { APP_ROUTING } from './app.routes';

// Servicios


// Componentes
import { AppRoutingModule } from './app-routing.module';
import { NavbarComponent } from './components/shared/navbar/navbar.component';
import { FooterComponent } from './components/shared/footer/footer.component';

import { HomeComponent } from './components/home/home.component';
import { IntroductionComponent } from './components/introduction/introduction.component';
import { Tumbling20sComponent } from './components/tumbling20s/tumbling20s.component';
import { BlockchainComponent } from './components/blockchain/blockchain.component';
import { AboutComponent } from './components/about/about.component';
import { RightSideColumnComponent } from './components/shared/right-side-column/right-side-column.component';
import { DisclaimerComponent } from './components/disclaimer/disclaimer.component';
import { TaleComponent } from './components/tale/tale.component';
import { ProfileComponent } from './profile/profile.component';
import { TransportComponent } from './transport/transport.component';

@NgModule({
  declarations: [
    AppComponent,
    HomeComponent,
    NavbarComponent,
    FooterComponent,
    IntroductionComponent,
    Tumbling20sComponent,
    BlockchainComponent,
    AboutComponent,
    RightSideColumnComponent,
    DisclaimerComponent,
    TaleComponent,
    ProfileComponent,
    TransportComponent
  ],
  imports: [
    BrowserModule,
    FontAwesomeModule,
    AppRoutingModule,
    APP_ROUTING
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
