<template>
  <router-view/>
</template>

<script>
import widget from './components/widget.vue'
import position from './components/position.vue'

export default {
  name: 'App',
  components: {
    widget,
    position
  }
}
</script>

<style>
body {
  margin: 0;
}
</style>
