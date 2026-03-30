const mongoose = require('mongoose');

const DailyLogSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  date: { type: Date, required: true },
  completions: [{
    taskId: { type: mongoose.Schema.Types.ObjectId, ref: 'Task', required: true },
    completed: { type: Boolean, default: false },
  }],
});

DailyLogSchema.index({ user: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('DailyLog', DailyLogSchema);