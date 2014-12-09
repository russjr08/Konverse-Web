module.exports = (grunt)->

  require('load-grunt-tasks') grunt

  grunt.initConfig
    browserify:
      dist:
        files: 'build/main.js': 'src/main.coffee'
        options:
          transform: ['coffeeify']

    uglify:
      dist:
        files: 'build/main.min.js': 'build/main.js'

    watch:
      coffee:
        files: [
          'src/**/*.coffee',
          'src/**/*.js',
          '**/*.html',
          'assets/style.css',
          'assets/**/*.png']
        tasks: ['build']
        options:
          livereload: 1337

    connect:
      server:
        options:
          open: no
          port: 9002

    clean: dist: files: 'build'

  grunt.registerTask 'build', ['clean', 'browserify']
  grunt.registerTask 'default', ['build', 'connect', 'watch']
