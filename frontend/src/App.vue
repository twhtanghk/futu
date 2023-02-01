<template>
  <v-container>
    <v-row>
      <v-col><chart/></v-col>
      <v-col><chart/></v-col>
    </v-row>
    <v-row>
      <v-col><chart/></v-col>
      <v-col><chart/></v-col>
    </v-row>
  </v-container>
</template>

<script>
import chart from './components/chart.vue'

export default {
  name: 'App',
  components: {
    chart
  }
}
</script>

<style>
body {
  margin: 0;
}
</style>
