import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import { createPinia } from 'pinia'
import i18n from './i18n'

// Vant
import 'vant/lib/index.css'
import { Button, Tab, Tabs, Image as VanImage, Swipe, SwipeItem, Grid, GridItem, Search, Icon, Loading, Empty, Toast, Dialog, Popup, Cell, CellGroup, Form, Field, Divider, NavBar, Tabbar, TabbarItem, PullRefresh, List } from 'vant'

// Styles
import './styles/index.css'

const app = createApp(App)

// Vant components
app.use(Button)
app.use(Tab)
app.use(Tabs)
app.use(VanImage)
app.use(Swipe)
app.use(SwipeItem)
app.use(Grid)
app.use(GridItem)
app.use(Search)
app.use(Icon)
app.use(Loading)
app.use(Empty)
app.use(Toast)
app.use(Dialog)
app.use(Popup)
app.use(Cell)
app.use(CellGroup)
app.use(Form)
app.use(Field)
app.use(Divider)
app.use(NavBar)
app.use(Tabbar)
app.use(TabbarItem)
app.use(PullRefresh)
app.use(List)

app.use(createPinia())
app.use(router)
app.use(i18n)

app.mount('#app')
