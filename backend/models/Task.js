const mongoose = require('mongoose');

const TaskSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,  // This ensures every task is linked to a user
  },
  title: {
    type: String,
    required: true,
    trim: true,
  },
  category: {
    type: String,
    required: true,
    enum: ['Health', 'Fitness', 'Productivity', 'Learning', 'Personal', 'Work'],
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  lockedUntil: {
    type: Date,
    required: true,
  },
  isActive: {
    type: Boolean,
    default: true,
  },
});

// Add index for faster queries
TaskSchema.index({ user: 1, createdAt: -1 });

module.exports = mongoose.model('Task', TaskSchema);