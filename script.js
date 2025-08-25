document.getElementById('registrationForm').addEventListener('submit', function(e) {
    e.preventDefault();
    const name = this.name.value.trim();
    const email = this.email.value.trim();
    const team = this.team.value.trim();
    const messageDiv = document.getElementById('form-message');

    if (!name || !email) {
        messageDiv.textContent = "Please fill in all required fields.";
        messageDiv.style.color = "#ff4f4f";
        return;
    }

    // Simulate successful registration
    messageDiv.textContent = `Thank you, ${name}! Your registration has been received.`;
    messageDiv.style.color = "#00b894";
    this.reset();
});